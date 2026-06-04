import vim
import os

def file_extension(path):
    return path.split('.')[-1]

def print_error(errStr):
    cmd = f"echomsg \"{errStr}\""
    vim.command(cmd)

def get_files_from_tags():
    if os.path.exists('tags'):
        files = set([])
        with open('tags', 'r', encoding='utf-8', errors='ignore') as lines_in_file:
            for line in lines_in_file:
                if line.find("!_TAG_") == -1:
                    txt = line.split('\t')
                    files.add(txt[1])
        return sorted(list(files))
    else:
        print_error("tags -file is not found")
    return list()

def find_files_in_tags(file):
    filename = os.path.basename(file)
    files = []
    for tag_file in get_files_from_tags():
        if tag_file.find(filename) != -1:
            if os.path.basename(tag_file) == filename:
                files.append(tag_file)
    return files

def open_file(path):
    cmd = 'edit ' + path
    vim.command(cmd)

def get_other_file(file):
    # TODO Eero: if header file, return source and vice versa
    if file_extension(file) == 'cpp':
        return file[0:-3] + 'hpp'
    elif file_extension(file) == 'hpp': 
        return file[0:-3] + 'cpp'
    elif file_extension(file) == 'c': 
        return file[0:-1] + 'h'
    elif file_extension(file) == 'h': 
        return file[0:-1] + 'c'
    return None

def get_current_buffer_name():
    return vim.current.buffer.name

def get_files():
    current_buffer_name = get_current_buffer_name()
    other_file = get_other_file(current_buffer_name)
    if os.path.exists(other_file):
        return [other_file]
    else:
        return find_files_in_tags(other_file)
    return []
