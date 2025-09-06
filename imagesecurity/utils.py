import cv2
import numpy as np

# ----- Partitioning -----
def partition_image(image, rows=2, cols=2):
    h, w = image.shape[:2]
    new_h = (h // rows) * rows
    new_w = (w // cols) * cols
    image = cv2.resize(image, (new_w, new_h))  # Resize to make perfectly divisible

    part_height = new_h // rows
    part_width = new_w // cols

    parts = []
    for r in range(rows):
        for c in range(cols):
            part = image[r*part_height:(r+1)*part_height, c*part_width:(c+1)*part_width]
            parts.append(part)
    return parts


# ----- Stitching -----
from PIL import Image

import numpy as np

def stitch_image(parts, rows, cols):
    """Stitch OpenCV images (numpy arrays) into a grid."""
    # Ensure parts are numpy arrays and same size
    min_h = min(p.shape[0] for p in parts)
    min_w = min(p.shape[1] for p in parts)
    resized = [cv2.resize(p, (min_w, min_h)) for p in parts]

    # Fill grid
    grid = []
    for r in range(rows):
        row_imgs = resized[r * cols:(r + 1) * cols]
        if len(row_imgs) < cols:  # pad empty spaces
            row_imgs += [np.zeros_like(resized[0])] * (cols - len(row_imgs))
        grid.append(np.hstack(row_imgs))
    stitched = np.vstack(grid)
    return stitched



# ----- Key Generation -----
def logistic_map(r, x0, size):
    seq = []
    x = x0
    for _ in range(size):
        x = r * x * (1 - x)
        seq.append(int(x * 255))
    return np.array(seq, dtype=np.uint8)

def lfsr(seed, taps, size):
    sr = seed
    seq = []
    for _ in range(size):
        xor = 0
        for t in taps:
            xor ^= (sr >> t) & 1
        sr = ((sr << 1) & 0xFFFF) | xor
        seq.append(sr & 0xFF)
    return np.array(seq, dtype=np.uint8)

def generate_key_sequence(size, r=3.9, x0=None, lfsr_seed=None, taps=[0,2,3,5]):
    # Randomize seeds for each part
    if x0 is None:
        x0 = np.random.uniform(0.1, 0.9)
    if lfsr_seed is None:
        lfsr_seed = np.random.randint(1, 0xFFFF)
    k1 = logistic_map(r, x0, size)
    k2 = lfsr(lfsr_seed, taps, size)
    key = np.bitwise_xor(k1, k2)
    return key


# ----- Encrypt/Decrypt -----
def encrypt_image_part(part, key):
    flat = part.flatten()
    if key.size < flat.size:
        raise ValueError(f"Key size {key.size} is smaller than image size {flat.size}")
    encrypted = np.bitwise_xor(flat, key[:flat.size])
    return encrypted.reshape(part.shape)

def decrypt_image_part(part, key):
    # XOR is symmetric
    return encrypt_image_part(part, key)
