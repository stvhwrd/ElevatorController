# Embedded Elevator Controller

[![Join the chat at https://gitter.im/stvhwrd/ARM-elevator-controller](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/stvhwrd/ARM-elevator-controller?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)


A simple program to simulate an elevator controller, written in ARM Assembly Language and run on an EMBEST board.  The program responds to physical button pushes representative of the buttons in a four storey building.

###Constraints:

* On each level of the building there are two buttons to call the elevator - up and down.
* The elevator itself has four buttons - one for each level.
* The building has only one elevator, so the elevator stays at the level it was last used until called from another level.  In buildings with two elevators, generally at least one will always be available on the ground floor - this is not optimal for a single elevator.
