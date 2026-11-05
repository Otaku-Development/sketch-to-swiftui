import sys
from PIL import Image
import os

def remove_bottom_pixels(directory):
    # Get the list of files in the directory
    file_list = os.listdir(directory)
    
    # Iterate over each file in the directory
    for file_name in file_list:
        # Check if the file is an image
        if file_name.endswith(('.png', '.jpg', '.jpeg', '.gif')):
            file_path = os.path.join(directory, file_name)
            
            # Open the image using Pillow
            image = Image.open(file_path)
            
            # Get the dimensions of the image
            width, height = image.size
            
            # Calculate the new height after removing 120 pixels from the bottom
            new_height = height - 120
            
            # Create a new image with the updated dimensions
            new_image = image.crop((0, 0, width, new_height))
            
            # Save the new image with the same file name
            new_file_path = os.path.join(directory, file_name)
            new_image.save(new_file_path)
            
            print(f"Processed image: {file_name}")
    
    print("All images processed successfully.")

if __name__ == "__main__":
    # Check if a directory is provided as a command-line argument
    if len(sys.argv) == 2:
        image_directory = sys.argv[1]
        # Call the function to remove the bottom pixels
        remove_bottom_pixels(image_directory)
    else:
        print("Please provide a directory path as a command-line argument.")
