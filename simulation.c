//------------------------------------------------------------------------------
// Description  : Simulates every lattice point on a grid moving through a 
//                  vector field using a two variable equation f(x, y)
//
// File Name    : simulation.c
// Authors      : Liam Lawrence
// Created      : August 26, 2019
// Project      : Vector field simulation
// License      : GPLv2
// Copyright    : (C) 2019, Liam Lawrence
//
// Updated      : August 27, 2019
//------------------------------------------------------------------------------

#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#define X_SIZE              41              // The number of X lattice points
#define Y_SIZE              41              // The number of Y lattice points
#define TIME_STEP           0.01F           // The amount of time that passes in-between each step
#define NUMBER_OF_STEPS     1000            // The number of steps to simulate
#define X_LIMIT             2*X_SIZE        // The X limit where a point can move before it is marked as dead
#define Y_LIMIT             2*Y_SIZE        // The Y limit where a point can move before it is marked as dead

typedef struct {
    double x;
    double y;
    double x_velocity;
    double y_velocity;
    unsigned char is_dead;
} point_t;

typedef struct {
    double x;
    double y;
} vector_t;

FILE *fp;


// The equation used for simulating the vector field    -   f(x, y) = [v.x, v.y]
vector_t equation(double x, double y)
{
    vector_t v;

    v.x = -y * cos(y);
    v.y = x * sin(-x);

    // v.x = -x * sin(y);
    // v.y = -y * cos(x);

    // v.x = -y * cos(x);
    // v.y = x * sin(-x);

    // v.x = -x * sin(y);
    // v.y = x * sin(-x);

    return v;
}


// Fill the array with the lattice points of the grid
void init_grid(point_t grid[X_SIZE][Y_SIZE])
{
    for (int i = 0; i < X_SIZE; i++) {
        for (int j = 0; j < Y_SIZE; j++) {
            grid[i][j].x = i - X_SIZE/2;
            grid[i][j].y = j - Y_SIZE/2;
            grid[i][j].x_velocity = 0;
            grid[i][j].y_velocity = 0;
            grid[i][j].is_dead = 0;
        }
    }
}


// Move the points on the grid based on their location and current velocities
void update_grid(point_t grid[X_SIZE][Y_SIZE])
{
    vector_t vector;
    for (int i = 0; i < X_SIZE; i++) {
        for (int j = 0; j < Y_SIZE; j++) {

            if (!grid[i][j].is_dead) {
                vector = equation(grid[i][j].x, grid[i][j].y);
                grid[i][j].x_velocity = vector.x;
                grid[i][j].y_velocity = vector.y;

                grid[i][j].x += grid[i][j].x_velocity * TIME_STEP;
                grid[i][j].y += grid[i][j].y_velocity * TIME_STEP;

                if (abs(grid[i][j].x) > X_LIMIT || abs(grid[i][j].y) > Y_LIMIT) {           // If the point is too far off of the screen, consider it dead and stop it from moving
                    grid[i][j].x_velocity = 0;                                              //    this helps not kill the system when points go flying off on an exponential curve
                    grid[i][j].y_velocity = 0;
                    grid[i][j].is_dead = 1;
                }
            }
        }
    }
}


// Write to the output file the current positions of the points
void print_grid(point_t grid[X_SIZE][Y_SIZE])
{
    for (int i = 0; i < X_SIZE; i++) {
        for (int j = 0; j < Y_SIZE; j++) {
            fprintf(fp, "%f\t%f\n", grid[i][j].x, grid[i][j].y);
        }
    }
}


// Write to the output file the velocities of the lattice points
void print_lattice_velocities(point_t grid[X_SIZE][Y_SIZE])
{
    vector_t vector;
    for (int i = 0; i < X_SIZE; i++) {
        for (int j = 0; j < Y_SIZE; j++) {
            vector = equation(grid[i][j].x, grid[i][j].y);
            fprintf(fp, "%f\t%f\n", vector.x, vector.y);
        }
    }
}


int main()
{
    printf("Simulating points....\n");
    point_t grid[X_SIZE][Y_SIZE];
    init_grid(grid);

    fp = fopen("./data/simulation_data.txt", "w");                                      // The file that will be the input of the processing program
    fprintf(fp, "%d\n%d\n%f\n%d\n", X_SIZE, Y_SIZE, TIME_STEP, NUMBER_OF_STEPS);        // Records the parameters for the simulation
    print_lattice_velocities(grid);                                                     // Records the velocities of the lattice points

    for (int step = 0; step < NUMBER_OF_STEPS; step++) {                                // Records the movement of every point for each step
        update_grid(grid);
        print_grid(grid);
    }

    fclose(fp);
}

