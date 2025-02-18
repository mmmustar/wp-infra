# Monitoring Setup

Ce projet utilise Ansible pour installer et configurer Grafana et Prometheus sur vos serveurs.

## Structure du projet

- **ansible.cfg** : Configuration d'Ansible.
- **playbook.yml** : Playbook principal qui inclut les rôles.
- **inventory/hosts.ini** : Inventaire des hôtes.
- **roles/** : Contient les rôles pour Grafana et Prometheus.
  - **grafana/** : Rôle pour l'installation et la configuration de Grafana.
  - **prometheus/** : Rôle pour l'installation et la configuration de Prometheus.
