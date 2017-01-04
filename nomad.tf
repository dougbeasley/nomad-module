resource "google_compute_instance" "nomad" {
    count = "${var.servers}"

    name = "nomad-${count.index}"
    zone = "${var.region_zone}"
    tags = ["${var.tag_name}"]

    machine_type = "${var.machine_type}"

    disk {
        image = "${lookup(var.machine_image, var.platform)}"
    }

    network_interface {
        network = "default"

        access_config {
            # Ephemeral
        }
    }

    metadata {
        ssh-keys = "${lookup(var.user, var.platform)}:${file("${var.public_key_path}")}"
    }

    service_account {
        scopes = ["https://www.googleapis.com/auth/compute.readonly"]
    }

    connection {
        user        = "${lookup(var.user, var.platform)}"
        private_key = "${file("${var.private_key_path}")}"
    }

    provisioner "file" {
        source      = "${path.module}/scripts/${lookup(var.service_conf, var.platform)}"
        destination = "/tmp/${lookup(var.service_conf_dest, var.platform)}"
    }

    provisioner "remote-exec" {
        inline = [
            "echo ${var.servers} > /tmp/nomad-server-count",
            "echo ${google_compute_instance.nomad.0.network_interface.0.address} > /tmp/nomad-server-addr",
        ]
    }

    provisioner "remote-exec" {
        scripts = [
            "${path.module}/../shared/scripts/install.sh",
            "${path.module}/../shared/scripts/service.sh",
            "${path.module}/../shared/scripts/ip_tables.sh",
        ]
    }
}

resource "google_compute_firewall" "nomad_ingress" {
    name = "nomad-internal-access"
    network = "default"

    allow {
        protocol = "tcp"
        ports = [
            "4646", # HTTP
            "4647", # RPC
            "4648"  # Serf
        ]
    }

    source_tags = ["${var.tag_name}"]
    target_tags = ["${var.tag_name}"]
}
