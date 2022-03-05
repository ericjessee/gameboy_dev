#!/bin/bash
echo "assembling..."
rgbasm -L -o test_motion_delaytimer.o test_motion_delaytimer.gameboy.asm
echo "linking..."
rgblink -o test_motion_delaytimer.gb test_motion_delaytimer.o
echo "fixing..."
rgbfix -v -p 0xFF test_motion_delaytimer.gb
echo "linking symbols..."
rgblink -n test_motion_delaytimer.sym test_motion_delaytimer.o
echo "done"