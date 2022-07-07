import os
import binascii
import hashlib
from secp256k1 import PrivateKey
from Crypto.Hash import RIPEMD160
import base58

# randomness = time.time()
# print(float(randomness))

n = 1000


# # Step 1 :  "Pick a number between 1 and 2^256."
# # the private key can be any number between 1 and n - 1, where n is a constant (n = 1.158 * 1077, slightly less than 2 256)
def create_random_number(n):
    return int(binascii.hexlify(os.urandom(n)), 16)


def gen_private_key():
    private_key_num_less = True

    while private_key_num_less:
        random_number = create_random_number(n)
        private_key_num_less = n > float(1.158 * 10 ** 77)

    encoded_number = str(random_number).encode()
    hashed_number = hashlib.sha256(encoded_number)
    hashed_number_upper = hashed_number.hexdigest().upper()
    print(f"Private Key: {hashed_number_upper}")
    return hashed_number_upper


# The public key is calculated from the private key using elliptic curve multiplication
# which is irreversible: K = k * G, where k is the private key, G is a constant point called the generator point, and K is the resulting public key.
def gen_public_key(pri_key):
    privkey = PrivateKey(bytes(bytearray.fromhex(pri_key)))
    pubkey_ser_uncompressed = privkey.pubkey.serialize(compressed=False)
    pubkey_ser_uncompressed_hex = pubkey_ser_uncompressed.hex()
    print(f"Public Key: {pubkey_ser_uncompressed_hex}")
    return pubkey_ser_uncompressed_hex


# Pass it through the sha256 function, then the ripemd160 function
def ripem160_sha256_pub_key(pubkey_ser):
    pubkey_hash256_hex = hashlib.sha256(binascii.unhexlify(pubkey_ser)).digest()
    pubkey_hash256_ripem = (
        hashlib.new("ripemd160", pubkey_hash256_hex).hexdigest().upper()
    )
    print(f"RIPEM160 and Sha256 hashed Public Key: {pubkey_hash256_ripem}")
    return pubkey_hash256_ripem


# Then take the four first bytes of the sha256 hash of the sha256 hash of this word and append it to the end.
def sha256_sha256(pubkey_hash256_ripem):
    return hashlib.sha256(
        hashlib.sha256(binascii.unhexlify(pubkey_hash256_ripem)).digest()
    ).hexdigest()[:8]


def create_btc_address():
    private_key = gen_private_key()
    public_key = gen_public_key(private_key)
    pubkey_hash256_ripem = ripem160_sha256_pub_key(public_key)

    # Add 00 to the begining. It is called “network byte” and means we are on Bitcoin main network.
    pubkey_hash256_ripem = "00" + pubkey_hash256_ripem
    print(f"Add 00: {pubkey_hash256_ripem}")

    hash_hash_first_4bytes = sha256_sha256(pubkey_hash256_ripem)
    result = pubkey_hash256_ripem + hash_hash_first_4bytes
    print(f"Add first 4byte hash: {result}")

    check_enc = base58.b58encode(bytes.fromhex(result))
    print((check_enc))
    return check_enc


if __name__ == "__main__":
    create_btc_address()
