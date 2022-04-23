import os

from git import Repo
import gnupg


class GLSARepo:
    def __init__(self, path, password, gpghome, ssh_key):
        self.repo_path = path
        self.repo = Repo.init(path)
        self.gpghome = gpghome
        self.smtpuser = "glsamaker@gentoo.org"
        self.password = password
        self.ssh_key = ssh_key

        self.repo.config_writer().set_value("user", "name", "GLSAMaker").release()
        self.repo.config_writer().set_value("user", "email", self.smtpuser).release()

    def get_key(self) -> str:
        gpg = gnupg.GPG(gnupghome=self.gpghome)
        return gpg.list_keys()[0]

    def commit(self, glsa):
        filename = os.path.join(self.repo_path, "glsa-{}.xml".format(glsa.glsa_id))
        with open(filename, "w+") as f:
            f.write(glsa.generate_xml())
        self.repo.git.add(filename)
        key = self.get_key()
        # TODO: xml linting before commit
        os.environ["GNUPGHOME"] = self.gpghome
        os.system(
            f"gpg-agent --daemon --allow-preset-passphrase --homedir={self.gpghome}"
        )
        os.system(
            "gpg-connect-agent 'PRESET_PASSPHRASE {} -1 {}'".format(
                key["keygrip"], self.password.encode("utf-8").hex()
            )
        )
        self.repo.git.commit(
            "--message",
            "Add glsa-{}.xml".format(glsa.glsa_id),
            f"--gpg-sign={key['fingerprint']}",
            "--signoff",
        )
        del os.environ["GNUPGHOME"]

    def push(self):
        # TODO: we should handle StrictHostKeyChecking better
        ssh_command = "ssh -i {} -o StrictHostKeyChecking=no".format(self.ssh_key)
        with self.repo.git.custom_environment(GIT_SSH_COMMAND=ssh_command):
            self.repo.remotes.origin.push()
