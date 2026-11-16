
import hashlib
from cryptography.hazmat.primitives.asymmetric import rsa, padding
from cryptography.hazmat.primitives import hashes
from cryptography.exceptions import InvalidSignature

# Store vehicle details
vehicles = {}

# Public and Private Keys
private_key = None
public_key = None

# Store signed message and signature
saved_message = None
saved_signature = None

# 1. SHA-256 Hashing
def generate_hash():

    message = input("Enter your message: ")

    sha256_hash = hashlib.sha256(
        message.encode()
    ).hexdigest()

    print("\nSHA-256 Hash:")
    print(sha256_hash)

# 2. Generate Public and Private Keys
def generate_keys():

    global private_key, public_key
    global saved_message, saved_signature

    private_key = rsa.generate_private_key(
        public_exponent=65537,
        key_size=2048
    )

    public_key = private_key.public_key()

    saved_message = None
    saved_signature = None

    print("\nKeys generated successfully!")
    print("Private Key and Public Key are ready.")

# 3. Digital Signature
def create_signature():

    global saved_message, saved_signature

    if private_key is None:
        print("\nPlease generate keys first!")
        return

    message = input("Enter message to sign: ")

    signature = private_key.sign(
        message.encode(),
        padding.PSS(
            mgf=padding.MGF1(hashes.SHA256()),
            salt_length=padding.PSS.MAX_LENGTH
        ),
        hashes.SHA256()
    )

    saved_message = message
    saved_signature = signature

    print("\nDigital Signature Created!")
    print("Signature:")
    print(signature.hex())

# 4. Verify Digital Signature
def verify_signature():

    if public_key is None:
        print("\nPlease generate keys first!")
        return

    if saved_signature is None:
        print("\nPlease create a digital signature first!")
        return

    message = input("Enter message to verify: ")

    try:
        public_key.verify(
            saved_signature,
            message.encode(),
            padding.PSS(
                mgf=padding.MGF1(hashes.SHA256()),
                salt_length=padding.PSS.MAX_LENGTH
            ),
            hashes.SHA256()
        )

        print("\nSignature is VALID!")

    except InvalidSignature:
        print("\nSignature is INVALID!")

    except Exception:
        print("\nVerification failed!")

# 5. Register Vehicle
def register_vehicle():

    number_plate = input("Enter Vehicle Number Plate: ").upper().strip()

    if not number_plate:
        print("\nNumber plate cannot be empty!")
        return

    if number_plate in vehicles:
        print("\nVehicle Number Plate already exists!")
        return

    owner = input("Enter Owner Name: ").strip()
    model = input("Enter Vehicle Model: ").strip()

    if not owner or not model:
        print("\nOwner name and model cannot be empty!")
        return

    vehicles[number_plate] = {
        "Owner": owner,
        "Model": model
    }

    print("\nVehicle Registered Successfully!")

# 6. Retrieve Vehicle
def get_vehicle():

    number_plate = input(
        "Enter Vehicle Number Plate: "
    ).upper().strip()

    if number_plate in vehicles:

        print("\nVehicle Details")
        print("----------------------")

        print("Number Plate:", number_plate)
        print("Owner:", vehicles[number_plate]["Owner"])
        print("Model:", vehicles[number_plate]["Model"])

    else:
        print("\nError: Vehicle Number Plate Not Found!")

# Main Menu
def main():

    while True:

        print("\n================================")
        print(" CRYPTOGRAPHY AND BLOCKCHAIN")
        print("================================")

        print("1. Generate SHA-256 Hash")
        print("2. Generate Public-Private Keys")
        print("3. Create Digital Signature")
        print("4. Verify Digital Signature")
        print("5. Register Vehicle")
        print("6. Get Vehicle Details")
        print("7. Exit")

        print("================================")

        choice = input("Enter your choice (1-7): ").strip()

        if choice == "1":
            generate_hash()

        elif choice == "2":
            generate_keys()

        elif choice == "3":
            create_signature()

        elif choice == "4":
            verify_signature()

        elif choice == "5":
            register_vehicle()

        elif choice == "6":
            get_vehicle()

        elif choice == "7":
            print("\nThank you for using the application!")
            print("Exiting program...")
            break

        else:
            print("\nInvalid Choice! Please select 1 to 7.")

# Run Application
if __name__ == "__main__":
    main()