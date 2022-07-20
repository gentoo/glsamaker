import os
from typing import Tuple

from git import Repo
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

        self.repo.config_writer().set_value("user", "name", "GLSAMaker").release()
        self.repo.config_writer().set_value("user", "email", self.smtpuser).release()

    def get_key(self) -> Tuple[str, str]:
        gpg = gnupg.GPG(gnupghome=self.gpghome)

        primary_key = gpg.list_keys()[0]
        keygrip = primary_key["keygrip"]

        if self.signing_key:
            return (self.signing_key, keygrip)

        signing_subkeys = [
            subkey for subkey in primary_key["subkeys"] if "s" in subkey[1]
        ]

        return (signing_subkeys[0][0], keygrip)

    def commit(self, glsa):
        filename = os.path.join(self.repo_path, "glsa-{}.xml".format(glsa.glsa_id))
        with open(filename, "w+") as f:
            f.write(glsa.generate_xml())
        self.repo.git.add(filename)
        fingerprint, keygrip = self.get_key()
        # TODO: xml linting before commit
        os.environ["GNUPGHOME"] = self.gpghome
        os.system(
            f"gpg-agent --daemon --allow-preset-passphrase --homedir={self.gpghome}"
        )
        os.system(
            "gpg-connect-agent 'PRESET_PASSPHRASE {} -1 {}'".format(
                keygrip, self.password.encode("utf-8").hex()
            )
        )
        self.repo.git.commit(
            "--message",
            "Add glsa-{}.xml".format(glsa.glsa_id),
            f"--gpg-sign={fingerprint}",
            "--signoff",
        )
        del os.environ["GNUPGHOME"]

    def push(self):
        # TODO: we should handle StrictHostKeyChecking better
        ssh_command = "ssh -i {} -o StrictHostKeyChecking=no".format(self.ssh_key)
        with self.repo.git.custom_environment(GIT_SSH_COMMAND=ssh_command):
            self.repo.remotes.origin.push()
