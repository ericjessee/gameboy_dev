#!/bin/bash
echo "assembling..."
rgbasm -L -o hello-world.o hello-world.gameboy.asm
echo "linking..."
rgblink -o hello-world.gb hello-world.o
echo "fixing..."
rgbfix -v -p 0xFF hello-world.gb
echo "linking symbols..."
rgblink -n hello-world.sym hello-world.o
echo "done"