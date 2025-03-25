


if (global.playerTurn = global.playersCount) 
{
    if (global.localPlayerId == global.playersList[global.playerTurn]) 
	{
        canLocalPlayerMakeMove = true;
    } else {
        canLocalPlayerMakeMove = false;
    }
} else {
    // Handle error or out-of-bounds situation
   //add_log("Error: playerTurn index is out of range!");
    canLocalPlayerMakeMove = true; // Prevent actions if the index is out of range
}