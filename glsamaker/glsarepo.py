import os
from typing import Tuple

from git import Repo
from git.exc import GitCommandError
import gnupg


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
        self.repo.config_writer().set_value("push", "gpgSign", "true").release()

    def get_key(self) -> Tuple[str, str]:
        gpg = gnupg.GPG(gnupghome=self.gpghome)
        primary_key = gpg.list_keys()[0]

        signing_subkeys = [
            subkey for subkey in primary_key["subkeys"] if "s" in subkey[1]
        ]

        if self.signing_key:
            for subkey in signing_subkeys:
                if subkey[0] == self.signing_key or subkey[2] == self.signing_key:
                    return (self.signing_key, subkey[3])
            # If we make it here, we didn't find the subkey we were
            # looking for.
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
        try:
            self.repo.git.commit(
                "--message",
                "Add glsa-{}.xml".format(glsa.glsa_id),
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
            self.repo.remotes.origin.push()
