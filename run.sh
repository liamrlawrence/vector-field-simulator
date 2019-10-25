#!/bin/bash

clear
gcc simulation.c -lm -o a.out
./a.out
rm a.out

processing-java --sketch=visualizer --force --run

