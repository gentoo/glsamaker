from smtplib import SMTP
from datetime import datetime

from git import Repo


def release_email(glsa):
    server = config["glsamaker"]["smtpserver"]
    user = config["glsamaker"]["smtpuser"]
    password = config["glsamaker"]["smtppass"]
    to = config["glsamaker"]["smtpto"]
    # TODO: Should theoretically be more configurable
    with SMTP(server, port=587) as smtp:
        smtp.starttls()
        smtp.login(user, password)
        smtp.sendmail(
            user,
            [to],
            glsa.generate_mail(date=datetime.now().strftime("%a, %d %b %Y %X")),
        )


def release_xml(glsa):
    repo = Repo.init("/var/lib/glsamaker/glsa")
    if "glsamaker" in config and "remote" in config["glsamaker"]:
        repo.remotes.origin.set_url(config["glsamaker"]["remote"])

    smtpuser = config["glsamaker"]["smtpuser"]
    repo.config_writer().set_value("user", "name", "GLSAMaker").release()
    repo.config_writer().set_value("user", "email", smtpuser).release()

    filename = "/var/lib/glsamaker/glsa/glsa-{}.xml".format(glsa.glsa_id)
    with open(filename, "w+") as f:
        f.write(glsa.generate_xml())
    repo.git.add(filename)
    # TODO: xml linting before commit
    repo.git.commit(
        "-m",
        "Add glsa-{}.xml".format(glsa.glsa_id),
        author="GLSAMaker <{}>".format(smtpuser),
    )
    ssh_key_path = config["glsamaker"]["ssh_key"]
    # TODO: we should handle StrictHostKeyChecking better, but we need
    # to ignore the hostkey when we e.g. are running from a docker
    # container
    ssh_command = "ssh -i {} -o StrictHostKeyChecking=no".format(ssh_key_path)
    with repo.git.custom_environment(GIT_SSH_COMMAND=ssh_command):
        repo.remotes.origin.push()
