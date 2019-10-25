//------------------------------------------------------------------------------
// Description  : Visualizes the calculations from the C simulation
//
// File Name    : visualizer.pde
// Authors      : Liam Lawrence
// Created      : August 26, 2019
// Project      : Vector field simulation
// License      : GPLv2
// Copyright    : (C) 2019, Liam Lawrence
//
// Updated      : August 27, 2019
//------------------------------------------------------------------------------

class Point {
    float x;
    float y;

    Point(float a, float b)
    {
        this.x = a;
        this.y = b;
    }
}

class Vector {
    float xv;
    float yv;
    float magnitude;
    float angle;
    color c;

    Vector(float init_xv, float init_yv)
    {
        this.xv = init_xv;
        this.yv = init_yv;

        this.magnitude = sqrt(this.xv*this.xv + this.yv*this.yv);
        this.c = color(200, 200, 200);

        this.angle = (float)Math.atan2(this.yv, this.xv);
    }
}


// IO variables
String line_break = "----------------------------------------";
String[] pieces;
BufferedReader reader;
PImage img;
PImage dark_img;

// Vector variables
Vector[][] lattice_vectors;                // Holds all of the lattice vectors
int ARROW_MAGNITUDE             = 15;      // Size in pixels of the magnitude of the arrows
int ARROW_WINGS                 = 5;       // Size in pixels of the "wings" of the arrows
float MAGNITUDE_CUTOFF          = 0.5;     // If a vector's magnitude is below this threshold, draw it as a dot instead of an arrow
int MAGNITUDE_COLOR_OFFSET      = 200;     // The amount to shift Hue around on the coloring of the vectors
int MANGITUDE_COLOR_BRIGHT      = 150;     // How bright the vectors are when FOCUS_DOT is disabled
int MANGITUDE_COLOR_DARK        = 50;      // How dark the vectors are when FOCUS_DOT is enabled
int MAGNITUDE_COLOR_INTENSITY;             // Changes the intensity of the magnitudes (not user set)

// Simulation parameters
int X_SIZE;                             // Number of X lattice points
int Y_SIZE;                             // Number of Y lattice points
float TIME_STEP;                        // Amount of time that passes between each frame
int NUMBER_OF_STEPS;                    // The total number of frames calculated

Point[][][] grid;                       // Holds the simulation data
int current_step = 0;                   // Which step of the simulation we are on
boolean IS_PAUSED = false;				// Flag for whether or not the visualizer is paused
boolean FOCUS_DOTS = false;             // Sets whether the background or the dots have more focus
boolean FOCUS_DIRECTION = false;        // Sets which direction the focused dots change color (Top->Bottom / Left->Right)
                                        //                                                        True         False


void setup()
{
    colorMode(HSB, 255);
    size(1200, 1200); 
    reader = createReader("../data/simulation_data.txt");


    // Load the simulation parameters
    println("Reading in simulation parameters....");
    X_SIZE = int(read_line());
    Y_SIZE = int(read_line());
    TIME_STEP = float(read_line());
    NUMBER_OF_STEPS = int(read_line());
    println(line_break);
    println("X-Size:\t\t\t" + X_SIZE + "\nY-Size:\t\t\t" + Y_SIZE + "\nTime Step:\t\t" + TIME_STEP + "\nNumber of Steps:\t" + NUMBER_OF_STEPS);
    println(line_break);


    // Solves the lattice vectors (this must come before the grid has the simulation data loaded into it due to the structure of the C program)
    lattice_vectors = new Vector[X_SIZE][Y_SIZE];
    println("Calculating lattice vectors....");
    init_lattice_vectors();


    // Load the grid with the simulation data
    grid = new Point[X_SIZE][Y_SIZE][NUMBER_OF_STEPS];
    println("Initializing grid....");
    init_grid();
    println("Loading simulation data....");
    load_grid_data();   


    // Draws the calculated lattice vectors and then saves it as a static background image to use in draw() (You only run these loops once, then you just load in the image as the background)
    println("Weighing and drawing the lattice vectors....");
    background(0);
    translate(width/2, height/2);
    scale(1, -1);
    strokeWeight(2);

    // Dark background
    MAGNITUDE_COLOR_INTENSITY = MANGITUDE_COLOR_DARK;
    colorize_lattice_vectors();
    for (int i = 0; i < X_SIZE; i++) {
        for (int j = 0; j < Y_SIZE; j++) {
            draw_lattice_vector(i - X_SIZE/2, j - Y_SIZE/2, lattice_vectors[i][j]);         // The XY_SIZE/2 is so the numbers straddle the axes
        }
    }
    saveFrame("../data/dark_background.png");
    dark_img = loadImage("../data/dark_background.png");

    // Bright background
    background(0);
    MAGNITUDE_COLOR_INTENSITY = MANGITUDE_COLOR_BRIGHT;
    colorize_lattice_vectors();
    for (int i = 0; i < X_SIZE; i++) {
        for (int j = 0; j < Y_SIZE; j++) {
            draw_lattice_vector(i - X_SIZE/2, j - Y_SIZE/2, lattice_vectors[i][j]);
        }
    }
    saveFrame("../data/background.png");
    img = loadImage("../data/background.png");

    println("Running simulation....");
}


// Read in a line using the reader object and return it
String read_line()
{
    String line = "";

    try {
        line = reader.readLine();
    } catch (IOException e) {
        e.printStackTrace();
        println("ERROR READING FILE");
        noLoop();
    }

    return line;
}


// Initialize an empty grid
void init_grid()
{
    for (int step = 0; step < NUMBER_OF_STEPS; step++) {
        for (int i = 0; i < X_SIZE; i++) {
            for (int j = 0; j < Y_SIZE; j++) {
                grid[i][j][step] = new Point(0, 0);
            }
        }
    }
}


// Load the information from the C-simulation into the empty grid
void load_grid_data()
{
    for (int step = 0; step < NUMBER_OF_STEPS-1; step++) {
        for (int i = 0; i < X_SIZE; i++) {
            for (int j = 0; j < Y_SIZE; j++) {
                pieces = split(read_line(), TAB);
                grid[i][j][step].x = float(pieces[0]) * (width / X_SIZE);           // The reason for the width/X_SIZE is so it scales to the viewing window
                grid[i][j][step].y = float(pieces[1]) * (height / Y_SIZE);          //                   height/Y_SIZE
            }
        }
    }
}


// Initialize the array that holds the information for the lattice vectors
void init_lattice_vectors()
{
    for (int i = 0; i < X_SIZE; i++) {
        for (int j = 0; j < Y_SIZE; j++) {
            pieces = split(read_line(), TAB);
            lattice_vectors[i][j] = new Vector(float(pieces[0]), float(pieces[1]));
        }
    }
}


// Color the lattice vectors to represent their relative strength compared to the others
void colorize_lattice_vectors()
{
    // Find the max and min of the magnitudes of the lattice vectors
    float max_magnitude = -100000000.0;
    float min_magnitude =  100000000.0;

    for (int i = 0; i < X_SIZE; i++) {
        for (int j = 0; j < Y_SIZE; j++) {
            if (lattice_vectors[i][j].magnitude < min_magnitude)
                min_magnitude = lattice_vectors[i][j].magnitude;

            if (lattice_vectors[i][j].magnitude > max_magnitude)
                max_magnitude = lattice_vectors[i][j].magnitude;
        }
    }


    // Assigns a color based on relative magnitude to each of the vectors
    float magnitude_range = max_magnitude - min_magnitude;

    for (int i = 0; i < X_SIZE; i++) {
        for (int j = 0; j < Y_SIZE; j++) {
            lattice_vectors[i][j].c = color(MAGNITUDE_COLOR_OFFSET - (lattice_vectors[i][j].magnitude / magnitude_range) * 255, 255, MAGNITUDE_COLOR_INTENSITY);
        }
    }
}


// Draws all of the lattice vectors onto the screen
void draw_lattice_vector(int cx, int cy, Vector v)
{
    pushMatrix();
    translate(cx * (width / X_SIZE), cy * (height / Y_SIZE));
    rotate(v.angle);

    if (v.magnitude > MAGNITUDE_CUTOFF) {
        stroke(v.c);
        strokeWeight(2);
        line(0,0, ARROW_MAGNITUDE, 0);
        line(ARROW_MAGNITUDE, 0, ARROW_MAGNITUDE - ARROW_WINGS, -ARROW_WINGS);
        line(ARROW_MAGNITUDE, 0, ARROW_MAGNITUDE - ARROW_WINGS, ARROW_WINGS);
    } else {
        stroke(color(190, 200, MAGNITUDE_COLOR_INTENSITY));
        strokeWeight(10);
        point(0, 0);
    }

    popMatrix();
}


// Main loop
void draw()
{ 
    translate(width/2, height/2);
    scale(1, -1);
    strokeWeight(5);


    if (FOCUS_DOTS) {
        background(dark_img);
        for (int i = 0; i < X_SIZE; i++) {
            for (int j = 0; j < Y_SIZE; j++) {
                if (FOCUS_DIRECTION)
                    stroke((float)j/X_SIZE * 255.0, 255, 180);
                else
                    stroke((float)i/X_SIZE * 255.0, 255, 180);
                point(grid[i][j][current_step].x, grid[i][j][current_step].y); 
            }
        } 
    } else {
        background(img);
        stroke(0, 0, 255);
        for (int i = 0; i < X_SIZE; i++) {
            for (int j = 0; j < Y_SIZE; j++) {
                point(grid[i][j][current_step].x, grid[i][j][current_step].y); 
            }
        } 
    }


    current_step++;
    if (current_step == NUMBER_OF_STEPS) {
        println("Finished");
        noLoop();
    }
}


// If ENTER is pressed, change the focus of the visualizer
void keyPressed() {
  if (key == 10) {                              // key 10 is ENTER
      FOCUS_DOTS = !FOCUS_DOTS;
  } else if (key == 't' || key == 'T') {        // Top->Bottom coloring
      FOCUS_DIRECTION = true;
  } else if (key == 'r' || key == 'R') {        // Left->Right coloring
      FOCUS_DIRECTION = false;
  } else if (key == 'q' || key == 'Q') {        // Restart the simulation
      current_step = 0;
      IS_PAUSED = false;
      loop();
  } else if (key == 'p' || key == 'P') {        // Pause / resume the simulation
      IS_PAUSED = !IS_PAUSED;

      if (IS_PAUSED)
          noLoop();
      else
          loop();
  }
}
