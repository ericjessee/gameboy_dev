#fill a 16x16 square with mush_big.tiles
with open('map', 'wb') as file:
    rows = 32
    cols = 32
    windowRows = 16
    windowCols = 16
    itr = 128
    null = bytes(1)
    for row in range(rows):
        if row < windowRows:
            for col in range(cols):
                if col < windowCols:
                    bytes = (itr).to_bytes(1, byteorder='big')
                    file.write(bytes)
                    itr += 1
                    if itr > 255:
                        itr = 0
                else:
                    file.write(null)
        else:
            for col in range(cols):
                file.write(null)
            