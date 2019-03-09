var openpgp = require("openpgp"); // use as CommonJS, AMD, ES6 module or via window.openpgp
// const openpgp = window.openpgp;
// openpgp.initWorker({ path: "openpgp.worker.js" }); // set the relative web worker path
//
// console.log(openpgp.initWorker({ path: "openpgp.worker.js" }));

// const openpgp = require("openpgp"); // use as CommonJS, AMD, ES6 module or via window.openpgp

openpgp.initWorker({ path: "openpgp.pgp.js" }); // set the relative web worker path

const encryptDecryptFunction = async () => {
  const privKeyObj = (await openpgp.key.readArmored(privkey)).keys[0];
  await privKeyObj.decrypt(passphrase);

  // const options = {
  //   message: openpgp.message.fromText("Hello, World!"), // input as Message object
  //   publicKeys: (await openpgp.key.readArmored(pubkey)).keys, // for encryption
  //   privateKeys: [privKeyObj] // for signing (optional)
  // };

  var options = {
    userIds: [{ name: "David A", email: "davidamp@my.yorku.ca" }], // multiple user IDs
    curve: "ed25519", // ECC curve name
    passphrase: "abc123" // protects the private key
  };

  openpgp
    .generateKey(options)
    .then(function(key) {
      var privkey = key.privateKeyArmored; // '-----BEGIN PGP PRIVATE KEY BLOCK ... '
      var pubkey = key.publicKeyArmored; // '-----BEGIN PGP PUBLIC KEY BLOCK ... '
      var revocationCertificate = key.revocationCertificate; // '-----BEGIN PGP PUBLIC KEY BLOCK ... '

      console.log(key);
    })
    .catch(err => {
      console.log(err);
    });

  options = {
    message: openpgp.message.fromBinary(new Uint8Array([0x01, 0x01, 0x01])), // input as Message object
    passwords: ["abc123"], // multiple passwords possible
    armor: true // don't ASCII armor (for Uint8Array output)
  };

  openpgp
    .encrypt({
      message: openpgp.message.fromText("Hello testing 21342345"),
      publicKeys: pubkey
    })
    .then(ciphertext => {
      encrypted = ciphertext.data; // '-----BEGIN PGP MESSAGE ... END PGP MESSAGE-----'
      return encrypted;
    })
    .catch(err => {
      console.log(err);
    });
  /*

    .then(async encrypted => {
      const options = {
        message: await openpgp.message.readArmored(encrypted), // parse armored message
        publicKeys: (await openpgp.key.readArmored(pubkey)).keys, // for verification (optional)
        privateKeys: [privKeyObj] // for decryption
      };

      openpgp.decrypt(options).then(plaintext => {
        console.log(plaintext.data);
        return plaintext.data; // 'Hello, World!'
      });


    });
*/
};

var options = {
  userIds: [{ name: "David A", email: "davidamp@my.yorku.ca" }], // multiple user IDs
  numBits: 4096, // RSA key size
  passphrase: "Participating in the hackathon!" // protects the private key
};

encryptDecryptFunction();
