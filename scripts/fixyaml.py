import os

def rename_files(directory):
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.yaml'):
                old_file_path = os.path.join(root, file)
                new_file_path = os.path.join(root, file.split('.yaml')[0] + '.yaml')
                print(new_file_path)
                os.rename(old_file_path, new_file_path)

if __name__ == "__main__":
    directory_to_search = 'tasks' # replace with your directory
    rename_files(directory_to_search)