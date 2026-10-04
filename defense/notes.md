## Title

# Motivation

## What is SSTV

## MOVE-IIIa

- quick mission overview and payloads
- goal of the thesis
  - software for sstv payloads
  - not just move but a modular system allowing different input and output devices where move-iiia is just one of them

# Theory



# Constraints

- environmental constraints
  - unserviceable
- important requirements
  - any number of cameras
  - how camera failures should be handled
  - update failure
  - firmware size

# Implementation

## Architecture

- show package diagram
- sstv exposes sstv encoding and decoding for all modes
- beacon provides the functions for satellites
- beacon-on-moveiiia implements that for MOVE-IIIa specifically
- beacon-on-tab5 is used for verification
- sstv is a library aiming for maximal compatibility
  - heapless encoding
  - minimal memory and cpu usage

## States

- state diagram
- update state diagram

# Verification

## Quality Assurance

- 

## Integration Test Setup

- Raspberry Pi used to act as the satellite bus and ground station
  - tests very orchistrated from the pi so they could be performed entirely automated
- in total 11 tests conducted
  - successful sstv transmission with both cameras
  - simulated failure case for either camera
  - successful update
  - all update failure paths
- the firmware size was around 690 kB
- modularity test
  - M5Stack Tab5 was used
  - wont launch into space, but has all necessary components needed for an SSTV system
  - single camera used for images and speakers to emit the tones
    - notably the camera is different from either one on MOVE-IIIa
  - verifies modularity since no implementation could be done if beacon and move-iiia carrier were too tightly coupled
  - all tests pass

# Discussion

# Demo

------------------------

# Fragen an Jasper

- kann ich die Diagramme vereinfachen (Beispiel: state machine nur mit Statenamen und Pfeilen)
