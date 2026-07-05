module ImageProcessing
    (generateMissingImages
    ) where 

import Codec.Picture
import Control.Monad
import System.Directory
import System.FilePath
import Data.Fixed (mod')


targetHeight :: Int
targetHeight = 85

saturationBoost :: Double
saturationBoost = 0.10

generateMissingImages :: IO()
generateMissingImages = do
    let sourceDir = "images/source"
        outputDir = "images/downsampled"

    -- look at all the images in source
    files <- listDirectory sourceDir
    -- if corresponding file doesn't exist in donwsampled

    forM_ files $ \filename -> do

        let sourcePath = sourceDir </> filename
        let outputPath = outputDir </> filename

        fileExists <- doesFileExist outputPath

        unless fileExists $ do 

            -- get source image
            result <- readImage sourcePath
            case result of 
                Left err -> putStrLn err
                Right dynImg -> do
                    let img = convertRGB8 dynImg
                    -- get dimensions of the downsample 
                    let targetWidth = calcTargetW (imageWidth img) (imageHeight img) targetHeight
            
                    --downsample image
                    let newImg = downsampleImage img targetWidth targetHeight

                    -- save it to the images/downsampled folder
                    saveJpgImage 100 outputPath $ ImageRGB8 newImg

calcTargetW :: Int -> Int -> Int -> Int
calcTargetW sourceW sourceH newH = round $ fromIntegral sourceW / fromIntegral sourceH * fromIntegral newH

downsampleImage :: Image PixelRGB8 -> Int -> Int -> Image PixelRGB8
downsampleImage sourceImage targetW targetH = 

    generateImage generator targetW targetH 
        where 
            generator x y = PixelRGB8 (fromIntegral r') (fromIntegral g') (fromIntegral b')
                where
                    neighbors = [(nx, ny) | nx <- [blockW * x .. blockW * (x+1) - 1],
                                            ny <- [blockH * y .. blockH * (y+1) - 1]] 
                    -- ratio between 
                    blockW = imageWidth sourceImage `div` targetW
                    blockH = imageHeight sourceImage `div` targetH

                    -- get the pixel at each neighbor coordinate
                    pixels = map (\(nx, ny) -> pixelAt sourceImage nx ny) neighbors
                    n = length pixels 
                    -- average the red, green, blue of all the neighbors
                    red = fromIntegral (sum (map (\(PixelRGB8 r _ _) -> fromIntegral r) pixels) `div` n)
                    green = fromIntegral (sum (map (\(PixelRGB8 _ g _) -> fromIntegral g) pixels) `div` n)
                    blue = fromIntegral (sum (map(\(PixelRGB8 _ _ b) -> fromIntegral b) pixels) `div` n)

                    (r', g', b') = saturatePixel saturationBoost (fromIntegral red,fromIntegral green, fromIntegral blue)




-- saturate RGB function ... 
saturatePixel :: Double -> (Int, Int, Int) -> (Int, Int, Int)
saturatePixel amount (r, g, b) =
    (r',b',g')
    where 
        (h,s,l) = boostSaturation amount (rgbToHsl r g b)
        (r', b', g') = hslToRgb h s l


rgbToHsl :: Int -> Int -> Int -> (Double,Double,Double)
rgbToHsl r g b = 
    let r' = fromIntegral r/255.0
        g' = fromIntegral g/255.0
        b' = fromIntegral b/255.0
        xMax = maximum [r', g', b']
        xMin = minimum [r', g', b'] 
        c = xMax - xMin
        l = (xMax + xMin) / 2.0
    
        h 
            | c == 0 = 0
            | xMax == r' = 60.0 * ((g'-b')/c `mod'` 6.0)
            | xMax == g' = 60.0 * ((b' - r')/c + 2.0)
            | otherwise = 60.0 * ((r'-g')/c + 4.0)

        s
            | c == 0 = 0 
            | otherwise = (xMax - l) / (min l (1.0- l))

    in (h, s, l)


hslToRgb :: Double -> Double -> Double -> (Int, Int, Int)
hslToRgb h s l = 
    (to255 r, to255 g, to255 b) 
        where 
            -- bug in 
            c = (1 - abs (2 * l - 1)) * s
            h' = h/60.0 
            x = c * (1 - abs ( h' `mod'` 2 - 1))
            m = l - c/2

            (r1,g1,b1) 
                    | h' < 1 = (c, x,0)
                    | h' < 2 = (x,c,0)
                    | h' < 3 = (0,c,x)
                    | h' < 4 = (0,x,c)
                    | h' < 5 = (x,0,c)
                    | h' < 6 = (c,0, x)
                    | otherwise = (c,x,0)

            r = r1 + m 
            g = g1 + m
            b = b1 + m

            to255 value = round (clamp 0 1 value * 255)

clamp :: Ord a => a -> a -> a -> a
clamp low high value = max low (min high value)

boostSaturation :: Double -> (Double, Double, Double) -> (Double, Double, Double)
boostSaturation amount (h, s, l)
    | s == 0    = (h, s, l)
    | otherwise = (h, s + strength * (1.0 - s), l)
  where
    strength = max 0.0 (min 1.0 amount)

