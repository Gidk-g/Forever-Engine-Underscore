function beatHit(curBeat)
{
    switch (curBeat)
    {
        case 16 | 80:
		    PlayState.gfSpeed = 2;
	    case 48 | 112:
    	    PlayState.gfSpeed = 1;
    }
}