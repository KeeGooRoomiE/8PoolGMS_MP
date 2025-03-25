/// @description Insert description here
// You can write your code in this editor

add_log("INIT Player turn swap");

global.playerTurn = !global.playerTurn;

sio_emit_change_turn();


