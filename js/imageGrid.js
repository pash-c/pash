const img = new Image();
img.crossOrigin = "anonymous";

const canvas = document.getElementById("vizzes");
const context = canvas.getContext("2d");
const cellSize = 5;

const paintings = [
    { file: "tranquility_levitan.jpg", artist: "Levitan", link:
  "https://en.wikipedia.org/wiki/Isaac_Levitan" },
    { file: "spring_in_italy_levitan.jpg", artist: "Levitan", link:
  "https://en.wikipedia.org/wiki/Isaac_Levitan" },
    { file: "a_quiet_monastery_levitan.jpg", artist: "Levitan", link:
  "https://en.wikipedia.org/wiki/Isaac_Levitan" },
    { file: "rye_shishkin.jpg", artist: "Shishkin", link:
  "https://en.wikipedia.org/wiki/Ivan_Shishkin" },
    { file: "wet_meadow_vasilyev.jpg", artist: "Vasilyev", link:
  "https://en.wikipedia.org/wiki/Fyodor_Vasilyev" },
  { file: "thaw_vasilyev.jpg", artist: "Vasilyev", link:
  "https://en.wikipedia.org/wiki/Fyodor_Vasilyev" },
  ];
const pick = paintings[Math.floor(Math.random() * paintings.length)];
const creditLink = document.querySelector(".image-credit");
creditLink.href = pick.link;
creditLink.textContent = pick.artist;
img.src = `images/downsampled/${pick.file}`;


let grid = []
let ogGrid = []
img.addEventListener("load", () => {

    //load image off screen
    let can = document.createElement('canvas');
    let ctx = can.getContext("2d");
    can.width = img.naturalWidth;
    can.height = img.naturalHeight;
    ctx.drawImage(img, 0, 0);
    img.style.display = "none";

    // get it's pixel data
    const imageData = ctx.getImageData(0,0,can.width,can.height);
    const pixelArray = imageData.data;

    //create the grid from pixel data
    initializeImageGrid(grid, pixelArray, can.width, can.height);
    ogGrid = grid.map(row => row.map(cell => ({...cell})));

    canvas.width = can.width * cellSize;
    canvas.height = can.height * cellSize;
    drawGrid(grid)
});

let clickCount = 0;
let running = false;
let animationFrameId = null;
canvas.addEventListener(
    "click",
    () => {

    if (rebuildProb >= 1.0){
        clickCount = 0;

        cancelAnimationFrame(animationFrameId);
        animationFrameId = null;
        running = false;

        grid = ogGrid.map(row => row.map(cell => ({...cell})));

        rebuildProb = 0;

        drawGrid(grid);
    }
    clickCount++;

    if (clickCount == 1) {
        fadeImageEdges(grid, grid.length, grid[0].length);
        drawGrid(grid);
    } 
    if (clickCount == 2) {
        addRandomNoise(grid, .6);
        drawGrid(grid);
    }
    if(clickCount >= 3){
        running = true;
    }
    if (running) {
            animationFrameId = requestAnimationFrame(tick);
        } else {
            cancelAnimationFrame(animationFrameId);
            animationFrameId = null;
        }
}
);

const updateInterval = 150;
let lastUpdate = 0;
let rebuildProb = 0;
function tick(time){
    if (!running) return;

    if (time - lastUpdate >= updateInterval){
        if(clickCount >= 4){
            rebuildProb= Math.min(rebuildProb+ .02, 1.0);
        }
        grid = conwayGame(grid, rebuildProb);
        lastUpdate = time;
    }
    drawGrid(grid);
    requestAnimationFrame(tick);
}


// loop through the image, make a 2D array of objects {r:, g:, b:, a:}

function initializeImageGrid(grid, pixels, width, height) {
    for (let x=0; x< width; x++){
        grid[x] = []
        for (let y=0; y<height; y++){
            
            let red_idx = (y * width + x) * 4
            let red = pixels[red_idx]
            let green = pixels[red_idx + 1]
            let blue = pixels[red_idx + 2]
            let alpha = pixels[red_idx + 3]

            grid[x][y] = {'r': red, 'g': green, 'b': blue, 'alpha': alpha/255}
        }
    }
}

function drawGrid(grid) {
    context.clearRect(0, 0, canvas.width, canvas.height);
    for (let x = 0; x < grid.length; x++) {
        for (let y = 0; y < grid[0].length; y++) {
            
            let c = grid[x][y]
            // change the fill style to the right one??
            context.fillStyle = `rgba(${c.r}, ${c.g}, ${c.b}, ${c.alpha})`
            context.fillRect(
                x * cellSize,
                y * cellSize,
                cellSize-1,
                cellSize-1
            );
        }
    }
}


// gpt generated function for fading the edges of the images
function fadeImageEdges(grid){
    const width = grid.length
    const height = grid[0].length
    const fadeX = width * 0.07;
    const fadeY = height * 0.07;
    const maxProbability = 0.85;

    for (let x = 0; x < width; x++) {
        for (let y = 0; y < height; y++) {
            const distanceX = Math.min(x, width - 1 - x);
            const distanceY = Math.min(y, height - 1 - y);

            const normalizedDistance = Math.min(
                distanceX / fadeX,
                distanceY / fadeY
            );

            if (normalizedDistance < 1) {

                const edgeStrength = 1 - normalizedDistance;

                const probability = maxProbability * edgeStrength ** 2;

                if (Math.random() < probability) {
                    grid[x][y].alpha = 0;
                }
            }
        }
    }
}

function addRandomNoise(grid, noiseProb){
    const width = grid.length
    const height = grid[0].length
    for (let x = 0; x < width; x++) {
        for (let y = 0; y < height; y++) {
            if (Math.random() < noiseProb) {
                grid[x][y].alpha = 0;
            }
        }
    }    
}


// CONWAY LOGIC
function conwayGame(grid, rebuildProb) {
    const width = grid.length
    const height = grid[0].length
    let next_grid = [];
    for (let x=0; x<width; x++){
        next_grid[x] = []
        for (let y=0; y<height; y++){
            let neigh = numLiveNeighbors(grid,x,y)
            let n = neigh[0]
            let avg_r = neigh[1]
            let avg_g = neigh[2]
            let avg_b = neigh[3]
            
            //slowly randomly rebuild the grid
            if (rebuildProb){
                if (Math.random() < rebuildProb){
                    next_grid[x][y] = {...ogGrid[x][y]};
                    continue;
                }
            }
            //this is averaged regular grid
            if (n === 3) {
                next_grid[x][y] = {'r': avg_r, 'g': avg_g, 'b': avg_b, 'alpha':1.0};
            }
            else if((grid[x][y].alpha != 0) && n === 2){
                next_grid[x][y] = {...grid[x][y]};
            }
            else{
                next_grid[x][y] = {...grid[x][y], alpha:0};
            }
        }
    }
    return next_grid
}
function numLiveNeighbors(grid, x, y) {
    const width = grid.length;
    const height = grid[0].length;
    let count=0;
    let red_total = 0;
    let blue_total = 0;
    let green_total = 0;
    for (let x1 = Math.max(x-1, 0); x1 <= Math.min(x+1, width-1); x1++ ){
        for (let y1 = Math.max(y-1, 0); y1 <= Math.min(y+1, height-1); y1++){

            if(x1===x && y1===y ){
                continue;
            }
            if(grid[x1][y1].alpha != 0){
                red_total += grid[x1][y1].r
                green_total += grid[x1][y1].g
                blue_total += grid[x1][y1].b
                count += 1
            }
        }
    }
    if (count == 0 ) return [0,0,0,0]
    return [count, red_total/count, green_total/count, blue_total/count];
}


