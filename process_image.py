import pygame

def getPixelArray(filename):
    try:
        image = pygame.image.load(filename)
    except pygame.error, message:
        print "Cannot load image:", filename
        raise SystemExit, message
    
    return pygame.surfarray.array3d(image)

pixels = getPixelArray('nyancat.png')
for x in range(0,32):
  for y in range(0,32):
    print format(pixels[x][y][2],'02x')+format(pixels[x][y][1],'02x')+format(pixels[x][y][0],'02x')