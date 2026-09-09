# Passive Radar Project

## Project Overview

This project is about building a simple passive radar simulation in MATLAB.

Passive radar does not transmit its own signal. It uses signals that already exist, such as radio or television signals. The system compares a reference signal with a surveillance signal to look for reflected signals from possible targets.

I am still learning passive radar and signal processing, so the project will be developed step by step.

## Project Workflow

The project has four main stages:

1. Reference and surveillance signal generation
2. Range-Doppler processing
3. Target detection
4. Target tracking

At the moment, I am working on the first stage and preparing for basic Range-Doppler processing.

## Current Progress

So far, I have:

- Completed the project design artefact
- Created and organised the GitHub repository
- Created folders for code, data, results, and documents
- Generated a simple reference signal in MATLAB
- Created a surveillance signal with a 20-sample delay
- Used cross-correlation to estimate the delay
- Successfully detected the expected 20-sample delay
- Studied the basic ideas of passive radar, time delay, Doppler shift, cross-correlation, and Range-Doppler Maps

## Current MATLAB Test

The current MATLAB simulation creates a random reference signal.

A delayed copy of this signal is used as the surveillance signal. The surveillance signal has a known delay of 20 samples.

Cross-correlation is then used to compare the two signals. The correlation peak appears at 20 samples, which matches the delay added to the simulation.

This test shows that the basic delay-estimation method is working correctly.

## Project Structure

```text
passive-radar/
├── data/
├── docs/
├── results/
├── src/
│   ├── signal_generation/
│   ├── range_doppler/
│   ├── detection/
│   └── tracking/
└── README.md# passive-radar