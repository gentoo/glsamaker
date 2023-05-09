import os
from typing import Tuple

import gnupg
from flask import current_app as app
from git import Repo
from git.exc import GitCommandError


class GLSARepo:
    def __init__(self, path, password, gpghome, signing_key=None, ssh_key=None):
        self.repo_path = path
        self.repo = Repo.init(path)
        self.gpghome = gpghome
        self.smtpuser = "glsamaker@gentoo.org"
        self.password = password
        self.ssh_key = ssh_key
        self.signing_key = signing_key

        os.environ["GNUPGHOME"] = self.gpghome

        self.repo.config_writer().set_value("user", "name", "GLSAMaker").release()
        self.repo.config_writer().set_value("user", "email", self.smtpuser).release()

    def get_key(self) -> Tuple[str, str]:
        gpg = gnupg.GPG(gnupghome=self.gpghome)
        primary_key = gpg.list_keys()[0]

        signing_subkeys = [
            subkey for subkey in primary_key["subkeys"] if "s" in subkey[1]
        ]

        if not signing_subkeys:
            app.logger.info(
                "Didn't find any signing subkeys! This is normal if your signing key is the primary key."
            )

        if self.signing_key:
            # Signing key is the primary key
            if self.signing_key.endswith(primary_key["keyid"]):
                return (self.signing_key, primary_key["keygrip"])

            # Signing key is a subkey
            for subkey in signing_subkeys:
                # Subkey array is of the format:
                # [shortid, capabilities, longid, keygrip]
                # So we want to check if the signing_key is either of
                # the ID indices, and if so, return the keygrip
                if self.signing_key in (subkey[0], subkey[2]):
                    return (self.signing_key, subkey[3])

            # If we make it here, we didn't find the subkey we were
            # looking for.
            app.logger.info(
                "The specified signing key doesn't seem to be in the keyring!"
            )
            return ("", "")

        return (signing_subkeys[0][0], signing_subkeys[0][3])

    def commit(self, glsa):
        filename = os.path.join(self.repo_path, "glsa-{}.xml".format(glsa.glsa_id))
        with open(filename, "w+") as f:
            f.write(glsa.generate_xml())
        self.repo.git.add(filename)

        # TODO: xml linting before commit
        os.system(
            f"gpg-agent --daemon --allow-preset-passphrase --homedir={self.gpghome}"
        )

        # This needs to be done after starting the agent, else the gpg
        # calls will start their own agent
        fingerprint, keygrip = self.get_key()

        os.system(
            "gpg-connect-agent 'PRESET_PASSPHRASE {} -1 {}' /bye".format(
                keygrip, self.password.encode("utf-8").hex()
            )
        )

        message = [f"[ GLSA {glsa.glsa_id} ] {glsa.title}"]
        message += [""]

        for bug in sorted(glsa.get_bugs()):
            message += [f"Bug: https://bugs.gentoo.org/{bug}"]

        try:
            self.repo.git.commit(
                "--message",
                "\n".join(message),
                f"--gpg-sign={fingerprint}",
                "--signoff",
            )
        except GitCommandError:
            # If anything went wrong while committing, blow away our
            # changes
            self.repo.git.reset(filename)
            os.remove(filename)
            raise

    def push(self):
        # TODO: we should handle StrictHostKeyChecking better
        ssh_command = "ssh -i {} -o StrictHostKeyChecking=no".format(self.ssh_key)
        with self.repo.git.custom_environment(GIT_SSH_COMMAND=ssh_command):
            self.repo.remotes.origin.push(signed=True)
