# J.O.S.H. Jump
Inspired by Gravity Guy, J.O.S.H. Jump is a platformer game project where the player interacts with a pixelated environment by flipping the direction of the gravity of the environment (downward/upward). The environment consists of a constantly moving stream of obstacles that they player must maneuver past utilizing the single control provided to them: flip the gravity. The main objective of the game is for the user to avoid obstacles and reach the end of the level as fast as possible, gathering as many points as possible.</br>  
[Click here](https://youtu.be/mXg3eTzyErs) for a video demonstration!

## Tech: 
`Altera DE2-115 Board`, `Verilog`

## Motives
Being a great fan of the game Gravity Guy, I decided to make my own version of the game in a team of 4 using the hardware I had. This is a simplistic game with direct hardware interaction which provides a lot of speed and efficiency.

## Development
Developed in a team of 4. Utilizes Verilog to create the circuits on the DE2 board. Maps can be customized to provide more of a challenge to the player. A map is defined by a matrix of pixels defining the walls the player interacts with.

## Controls: 
SW[0] : Toggles gravity. Keep it down to signify gravity pointing down and switch it up to toggle gravity up.</br>
SW[1] : The 'go' switch. Turn it on to start the game if in the menu stage.

## Instructions:
Initially, turn on 'go' to start the game. Play the game using the gravity switch, helping Josh (the red block) avoiding obstacles and attempting to not get pushed back by walls. If Josh gets pushed back too far, the game will end, putting the game in the menu state. Repeat the instructions to restart the game. Enjoy!
