function generateStage()
{
    /**
    * hello, just wanna make it clear that you need to add your stage images to the
    * assets/backgrounds/<stageName> folder for it to appear on the chart editor
    * the stageName in this case is `exampleStage`
    * so my folder would be `assets/backgrounds/exampleStage/`
    **/

    stageName = 'exampleStage'; // sets this stage's name (needed for the graphics to actually load);
    setStageZoom(0.9); // sets the stage camera zoom;
    spawnGirlfriend(false); // whether girlfriend should be on the stage or not;

    /**
        Blend Modes, for all your image effect needs
                = AVAILABLE BLENDS =
                    "normal"
                    "darken"
                    "multiply"
                    "lighten"
                    "screen"
                    "overlay"
                    "hardlight"
                    "difference"
                    "add"
                    "subtract"
                    "invert"
    **/

    // create sprites for the stage

    // left to right, sprite ID, path, x, y, and if it should spawn on the foreground (above characters);
    createSprite('bgBack', 'backgrounds/' + stageName + '/stageback', -600, -300, false);
    setSpriteScrollFactor('bgBack', 0.9, 0.9);

    //
    createSprite('bgFront', 'backgrounds/' + stageName + '/stageFront', -650, 600, false);
    setSpriteScrollFactor('bgFront', 0.9, 0.9);

    //
    createSprite('bgCurtains', 'backgrounds/' + stageName + '/stagecurtains', -500, -300, false);
    setSpriteScrollFactor('bgCurtains', 0.9, 0.9);

    // extra functions for creating animated sprites, not used here because this is a stage with no animated graphics;

    /**
    * createAnimatedSprite('spriteID', 'path', 'spriteType (can be sparrow or packer)', xPosition, yPosition [['animationPrefix', 'nameOnXML', fps, whether it loops or not]], defaultAnimation, spawnOnForeground);
    * addSpriteAnimation('spriteID', [['newAnimationPrefix', 'nameOnXML", fps, whether it loops or not]]);
    * addSpriteOffset('spriteID', 'animationPrefix', xOffset, yOffset);
    * spritePlayAnimation('spriteID', 'animationPrefix');
    * setSpriteBlend('spriteID', 'blendModeString');
    * setSpriteSize('spriteID', newSize); // newSize is a float value
    * setSpriteAlpha('spriteID', newOpacityValue); // newOpacityValue is a float value
    **/
}

function repositionPlayers(boyfriend, dad, gf) // function used to reposition characters
{
    //boyfriend.x += 0;
    //boyfriend.y += 0;
    //gf.x += 0;
    //gf.y += 0;
    //dad.x += 0;
    //dad.y += 0;
}

function updateStage(curBeat) // stage updates
{
    //
}

function updateStageConst(elapsed) // stage constant updates
{
    //
}