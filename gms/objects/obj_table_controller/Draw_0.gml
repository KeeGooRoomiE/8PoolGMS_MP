/// @description Insert description here
// You can write your code in this editor

//if (player_ids[0] != 0)
//{
//	draw_sprite(spr_gui_checkmark,0,room_width-256,room_height-128);
//}
//if (player_ids[1] != 0)
//{
//	draw_sprite(spr_gui_checkmark,0,room_width-128,room_height-128);
//}
//draw_text(0,0,string(fps_real));

for (var i = 0; i < array_length(global.playersList); i++)
{
	draw_sprite(spr_gui_checkmark,0,room_width-256+(128*i),room_height-128);
	draw_text(32,32+(i*24),"Player "+string(global.playersList[i]));
	//draw_text(room_width-256+(128*i)-64,room_height-128-64+24,"Dir:"+string(global.playersList[i]));
	//draw_text(room_width-256+(128*i)-64,room_height-128-64+48,"Force: "+string(global.players_list[i].));
}

draw_text(32,32+(i*24),"Player "+string(global.playersCount));
draw_text(room_width/2,room_height/2,"Player Turn: "+string(global.playerTurn+1));
if (canLocalPlayerMakeMove = true)
{
	draw_text(room_width/2,room_height/2+24,"Your Turn!");
}
draw_text(room_width/2,room_height/2+48,"Direction: "+string(global.playerDirection));
draw_text(room_width/2,room_height/2+72,"Force: "+string(global.playerForce));
//draw_text(room_width/2,room_height/2+48,"player_count:"+string(global.players_list.length) );

#region --- GLobal canvas works

//for (var i=0; i<global.players_list.length; i++)
//{
//	draw_text(0,0+i*24,"player_ids["+string(i)+"]="+string(global.players_list[i].id));
//}


#endregion