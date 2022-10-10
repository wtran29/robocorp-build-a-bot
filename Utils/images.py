from PIL import Image


def resize_image(filename, scale_percent=50):
    img = Image.open(filename)

    width = int(img.size[0] * scale_percent / 100)
    height = int(img.size[1] * scale_percent / 100)

    resized = img.resize((width, height), Image.ANTIALIAS)

    resized.save(filename)

