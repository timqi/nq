import argparse
import getpass
import hashlib
import os

from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import padding
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes


class AES256Cipher:
    def __init__(self, key):
        self.key = hashlib.sha256(key.encode("utf-8")).digest()
        self.key = hashlib.sha256(self.key).digest()

    def encrypt(self, plaintext):
        iv = os.urandom(16)
        padder = padding.PKCS7(128).padder()
        padded_data = padder.update(plaintext.encode("utf-8")) + padder.finalize()
        cipher = Cipher(algorithms.AES(self.key), modes.CBC(iv), backend=default_backend())
        encryptor = cipher.encryptor()
        ciphertext = encryptor.update(padded_data) + encryptor.finalize()
        return (iv + ciphertext).hex()

    def decrypt(self, ciphertext):
        ciphertext = bytes.fromhex(ciphertext)
        iv, ciphertext = ciphertext[:16], ciphertext[16:]
        cipher = Cipher(algorithms.AES(self.key), modes.CBC(iv), backend=default_backend())
        decryptor = cipher.decryptor()
        decrypted_data = decryptor.update(ciphertext) + decryptor.finalize()
        unpadder = padding.PKCS7(128).unpadder()
        plaintext = unpadder.update(decrypted_data) + unpadder.finalize()
        return plaintext.decode("utf-8")


def main(args):
    if args.action == "encrypt":
        p1 = getpass.getpass("input password: ")
        p2 = getpass.getpass("re input password: ")
        if len(p1) < 10 or p1 != p2:
            return print("invalid password!")
        print(AES256Cipher(p1).encrypt(args.text))
    elif args.action == "decrypt":
        p = getpass.getpass("password: ")
        text = AES256Cipher(p).decrypt(args.text)
        print("Decrypt succ!")
        if input("print serect to terminal?") == "y":
            print(text)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("action", choices=["encrypt", "decrypt"])
    parser.add_argument("--text", required=True)
    args = parser.parse_args()
    main(args)
