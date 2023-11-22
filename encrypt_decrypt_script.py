import os
import subprocess
import sys

def process_directory(directory, password, mode):
    vault_password_file = 'vault_pass.txt'

    # Write the password to a temporary file
    with open(vault_password_file, 'w') as file:
        file.write(password)

    # Walk through the directory and process each file
    for root, dirs, files in os.walk(directory):
        for file in files:
            file_path = os.path.join(root, file)
            # Decide based on mode
            if mode == "encrypt" and not file.endswith('.vault'):
                process_file(file_path, vault_password_file, 'encrypt')
            elif mode == "decrypt":
                try:
                    process_file(file_path, vault_password_file, 'decrypt')
                except subprocess.CalledProcessError:
                    print("Error: File {} is not encrypted. Skipping.".format(file_path))
    # Clean up: Remove the temporary password file
    os.remove(vault_password_file)

def process_file(file_path, vault_password_file, mode):
    command = ['ansible-vault', mode, file_path, '--vault-password-file', vault_password_file]
    subprocess.run(command, check=True)

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: python encrypt_decrypt_script.py [encrypt/decrypt] [directory] [vault_password]")
        sys.exit(1)

    mode = sys.argv[1]
    if mode not in ['encrypt', 'decrypt']:
        print("Invalid mode. Please choose 'encrypt' or 'decrypt'.")
        sys.exit(1)

    dir_to_process = sys.argv[2]
    vault_password = sys.argv[3]

    process_directory(dir_to_process, vault_password, mode)
