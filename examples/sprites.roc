app [main, Model] { ray: platform "../platform/main.roc" }

import ray.RocRay exposing [PlatformState, Texture, Rectangle]
import ray.RocRay.Keys as Keys

width = 800
height = 600

Model : {
    player : { x : F32, y : F32 },
    direction : [WalkUp, WalkDown, WalkLeft, WalkRight],
    dude : Texture,
    dudeAnimation : AnimatedSprite,
}

main : RocRay.Program Model _
main = { init, render }

init : Task Model []
init =

    RocRay.setTargetFPS! 60
    RocRay.setWindowSize! { width, height }
    RocRay.setWindowTitle! "Animated Sprite Example"

    dude = RocRay.loadTexture! "examples/assets/sprite-dude/sheet.png"

    Task.ok {
        player: { x: width / 2, y: height / 2 },
        direction: WalkRight,
        dude,
        dudeAnimation: {
            frame: 0,
            frameRate: 10,
            nextAnimationTick: 0,
        },
    }

render : Model, PlatformState -> Task Model []
render = \model, { timestampMillis, keys } ->

    RocRay.beginDrawing! White

    dudeAnimation = updateAnimation model.dudeAnimation timestampMillis

    RocRay.drawText! { pos: { x: 10, y: 10 }, text: "Rocci the Cool Dude", size: 40, color: Navy }
    RocRay.drawText! { pos: { x: 10, y: 50 }, text: "Use arrow keys to walk around", size: 20, color: Green }

    RocRay.drawTextureRec! {
        texture: model.dude,
        source: dudeSprite model.direction dudeAnimation.frame,
        pos: model.player,
        tint: White,
    }

    RocRay.endDrawing!

    (player, direction) =
        if Keys.down keys KeyUp then
            ({ x: model.player.x, y: model.player.y - 10 }, WalkUp)
        else if Keys.down keys KeyDown then
            ({ x: model.player.x, y: model.player.y + 10 }, WalkDown)
        else if Keys.down keys KeyLeft then
            ({ x: model.player.x - 10, y: model.player.y }, WalkLeft)
        else if Keys.down keys KeyRight then
            ({ x: model.player.x + 10, y: model.player.y }, WalkRight)
        else
            (model.player, model.direction)

    Task.ok { model & player, dudeAnimation, direction }

dudeSprite : [WalkUp, WalkDown, WalkLeft, WalkRight], U8 -> Rectangle
dudeSprite = \sequence, frame ->
    when sequence is
        WalkUp -> sprite64x64source { row: 8, col: frame % 9 }
        WalkDown -> sprite64x64source { row: 10, col: frame % 9 }
        WalkLeft -> sprite64x64source { row: 9, col: frame % 9 }
        WalkRight -> sprite64x64source { row: 11, col: frame % 9 }

AnimatedSprite : {
    frame : U8, # frame index, increments each tick
    frameRate : U8, # frames per second
    nextAnimationTick : U64, # milliseconds
}

updateAnimation : AnimatedSprite, U64 -> AnimatedSprite
updateAnimation = \{ frame, frameRate, nextAnimationTick }, timestampMillis ->

    if timestampMillis > nextAnimationTick then
        {
            frame: Num.addWrap frame 1,
            frameRate,
            nextAnimationTick: timestampMillis + (Num.toU64 (Num.round (1000 / (Num.toF64 frameRate)))),
        }
    else
        { frame, frameRate, nextAnimationTick }

# get the pixel coordinates of a 64x64 sprite in the spritesheet
sprite64x64source : { row : U8, col : U8 } -> Rectangle
sprite64x64source = \{ row, col } -> {
    x: 64 * (Num.toF32 col),
    y: 64 * (Num.toF32 row),
    width: 64,
    height: 64,
}
