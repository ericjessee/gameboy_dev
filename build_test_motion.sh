#!/bin/bash
echo "assembling..."
rgbasm -L -o test_motion.o test_motion.gameboy.asm
echo "linking..."
rgblink -o test_motion.gb test_motion.o
echo "fixing..."
rgbfix -v -p 0xFF test_motion.gb
echo "linking symbols..."
rgblink -n test_motion.sym test_motion.o
echo "done"