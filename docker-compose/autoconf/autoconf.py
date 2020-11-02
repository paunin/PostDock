#! /usr/bin/env python3

import sys
import argparse
import json

INDENT_LEVEL = 0
WAS_LAST_COLUMN = False

def resetIndent(value = 0):
    global INDENT_LEVEL, WAS_LAST_COLUMN
    WAS_LAST_COLUMN = False
    INDENT_LEVEL = value


def indentPrint(input, output, override_indent = None):
    global INDENT_LEVEL, WAS_LAST_COLUMN

    for string in input.split('\n'):
        if not override_indent:
            if string.strip() == '':
                resetIndent()
            else:
                if WAS_LAST_COLUMN:
                    INDENT_LEVEL += 1

                if not WAS_LAST_COLUMN and string[-1] == ':':
                    INDENT_LEVEL = max(INDENT_LEVEL - 1, 0)

                WAS_LAST_COLUMN = (string[-1] == ':')

            output += '\t'*INDENT_LEVEL+string+'\n'
        
        else:
            output += '\t'*override_indent+string+'\n'
    
    return output


def printHeader(output):
    output = indentPrint("version: '2'", output)
    resetIndent()
    return output


def printNetworks(output):
    output = indentPrint("networks:", output)
    output = indentPrint("cluster:", output)
    output = indentPrint("driver: bridge", output)
    output = indentPrint("", output)
    resetIndent()
    return output


def printVolumes(output):
    output = indentPrint("volumes:", output, 0)
    
    for mid in range(0,N_MASTERS):
        output = indentPrint("pgmaster{}:".format(mid), output, 1)

    for rid in range(0,N_REPLICAS):
        for wid in range(0,REPLICA_SIZE):
            output = indentPrint("pgslave{}-{}:".format(rid, wid), output, 1)
    
    output = indentPrint("barman:", output, 1)
    output = indentPrint("", output)

    resetIndent()
    return output


def printMaster(master_id, yml):
    yml = indentPrint("pgmaster{}:".format(master_id), yml)
    yml = indentPrint("build:", yml)
    yml = indentPrint("context: ../../src", yml)
    yml = indentPrint("dockerfile: Postgres-{}-Repmgr-{}.Dockerfile".format(PG_VERSION, REPMGR_VERSION), yml)
    yml = indentPrint("environment:", yml)
    yml = indentPrint("NODE_ID: {}".format(master_id), yml)
    yml = indentPrint("NODE_NAME: pgmaster{}".format(master_id), yml)
    yml = indentPrint("CLUSTER_NODE_NETWORK_NAME: pgmaster{}".format(master_id), yml)

    slaves = []
    for rid in range(0,N_REPLICAS):
        slaves.append("pgslave{}-0".format(rid))

    yml = indentPrint("PARTNER_NODES: \"pgmaster{},{}\"".format(master_id, ','.join(slaves)), yml)

    yml = indentPrint("REPLICATION_PRIMARY_HOST: pgmaster{}".format(master_id), yml)
    yml = indentPrint("NODE_PRIORITY: 100", yml)
    yml = indentPrint("SSH_ENABLE: 1", yml)
    yml = indentPrint("POSTGRES_PASSWORD: {}".format(PG_PASSWORD), yml)
    yml = indentPrint("POSTGRES_USER: {}".format(PG_USER), yml)
    yml = indentPrint("POSTGRES_DB: {}".format(PG_DB), yml)
    yml = indentPrint("CLEAN_OVER_REWIND: 0", yml)
    yml = indentPrint("CONFIGS_DELIMITER_SYMBOL: ;", yml)
    yml = indentPrint("CONFIGS: \"listen_addresses:'*';max_replication_slots:5\"", yml)
    yml = indentPrint("CLUSTER_NAME: pg_cluster", yml)
    yml = indentPrint("REPLICATION_DB: {}".format(REP_DB), yml)
    yml = indentPrint("REPLICATION_USER: {}".format(REP_USER), yml)
    yml = indentPrint("REPLICATION_PASSWORD: {}".format(REP_PASSWORD), yml)
    yml = indentPrint("ports:", yml)
    yml = indentPrint("- {}:5432".format(5420+master_id), yml)
    yml = indentPrint("volumes:", yml)
    yml = indentPrint("- pgmaster{}:/var/lib/postgresql/data".format(master_id), yml)
    yml = indentPrint("- ./ssh/:/tmp/.ssh/keys", yml)
    yml = indentPrint("networks:", yml)
    yml = indentPrint("cluster:", yml)
    yml = indentPrint("aliases:", yml)
    yml = indentPrint("- pgmaster{}".format(master_id), yml)

    resetIndent(2)
    yml = indentPrint("", yml)
    return yml


def printMasters(yml):
    for master_id in range(0,N_MASTERS):
        resetIndent(2)
        yml = printMaster(master_id, yml)
    
    resetIndent(2)
    return yml


def printSlave(rep_group_id, slave_id, yml):
    slave_uid = 10 * rep_group_id + slave_id + 1000

    if slave_id == 0:
        yml = indentPrint("pgslave{}-{}:".format(rep_group_id, slave_id), yml)
        yml = indentPrint("build:", yml)
        yml = indentPrint("context: ../../src", yml)
        yml = indentPrint("dockerfile: Postgres-{}-Repmgr-{}.Dockerfile".format(PG_VERSION, REPMGR_VERSION), yml)
        yml = indentPrint("environment:", yml)
        yml = indentPrint("NODE_ID: {}".format(slave_uid), yml)
        yml = indentPrint("NODE_NAME: node{}".format(slave_uid), yml)
        yml = indentPrint("CLUSTER_NODE_NETWORK_NAME: pgslave{}-{}".format(rep_group_id, slave_id), yml)
        yml = indentPrint("SSH_ENABLE: 1", yml)
        
        masters = []
        for mid in range(0,N_MASTERS):
            masters.append("pgmaster{}".format(mid))

        slaves = []
        for rid in range(0,N_REPLICAS):
            slaves.append("pgslave{}-0".format(rid))  # Only the first slave of each group

        yml = indentPrint("PARTNER_NODES: \"{}\"".format(','.join(masters+slaves)), yml)
        yml = indentPrint("REPLICATION_PRIMARY_HOST: {}".format(masters[slave_uid % N_MASTERS]), yml)

        yml = indentPrint("CLEAN_OVER_REWIND: 1", yml)
        yml = indentPrint("CONFIGS_DELIMITER_SYMBOL: ;", yml)
        yml = indentPrint("CONFIGS: \"max_replication_slots:10\"", yml)
        yml = indentPrint("ports:", yml)
        yml = indentPrint("- {}:5432".format(5450+slave_uid), yml)
        yml = indentPrint("volumes:", yml)
        yml = indentPrint("- pgslave{}-{}:/var/lib/postgresql/data".format(rep_group_id, slave_id), yml)
        yml = indentPrint("- ./ssh:/tmp/.ssh/keys", yml)
        yml = indentPrint("networks:", yml)
        yml = indentPrint("cluster:", yml)
        yml = indentPrint("aliases:", yml)
        yml = indentPrint("- pgslave{}-{}".format(rep_group_id, slave_id), yml)
    else:
        yml = indentPrint("pgslave{}-{}:".format(rep_group_id, slave_id), yml)
        yml = indentPrint("build:", yml)
        yml = indentPrint("context: ../../src", yml)
        yml = indentPrint("dockerfile: Postgres-{}-Repmgr-{}.Dockerfile".format(PG_VERSION, REPMGR_VERSION), yml)
        yml = indentPrint("environment:", yml)
        yml = indentPrint("NODE_ID: {}".format(slave_uid), yml)
        yml = indentPrint("NODE_NAME: node{}".format(slave_uid), yml)
        yml = indentPrint("CLUSTER_NODE_NETWORK_NAME: pgslave{}-{}".format(rep_group_id, slave_id), yml)

        yml = indentPrint("REPLICATION_PRIMARY_HOST: pgslave{}-0".format(rep_group_id), yml)
        yml = indentPrint("#USE_REPLICATION_SLOTS: 0", yml)
        yml = indentPrint("CONFIGS_DELIMITER_SYMBOL: ;", yml)
        yml = indentPrint("CONFIGS: \"listen_addresses:'*'\"", yml)
        yml = indentPrint("ports:", yml)
        yml = indentPrint("- {}:5432".format(5450+slave_uid), yml)
        yml = indentPrint("volumes:", yml)
        yml = indentPrint("- pgslave{}-{}:/var/lib/postgresql/data".format(rep_group_id, slave_id), yml)
        yml = indentPrint("networks:", yml)
        yml = indentPrint("cluster:", yml)
        yml = indentPrint("aliases:", yml)
        yml = indentPrint("- pgslave{}-{}".format(rep_group_id, slave_id), yml)

    yml = indentPrint("", yml)
    resetIndent(2)
    return yml


def printSlaves(yml):
    for rep_group_id in range(0,N_REPLICAS):
        for slave_id in range(0,REPLICA_SIZE):
            resetIndent(2)
            yml = printSlave(rep_group_id, slave_id, yml)

    resetIndent(2)
    return yml


def printBarmanBackup(yml):
    yml = indentPrint("barman:", yml)
    yml = indentPrint("build:", yml)
    yml = indentPrint("context: ../../src", yml)
    yml = indentPrint("dockerfile: Barman-{}-Postgres-{}.Dockerfile".format(BARMAN_VERSION, PG_VERSION), yml)
    yml = indentPrint("environment:", yml)
    yml = indentPrint("REPLICATION_USER: {}".format(REP_USER), yml)
    yml = indentPrint("REPLICATION_PASSWORD: {}".format(REP_PASSWORD), yml)
    yml = indentPrint("REPLICATION_HOST: pgmaster0", yml)
    yml = indentPrint("POSTGRES_PASSWORD: {}".format(PG_PASSWORD), yml)
    yml = indentPrint("POSTGRES_USER: {}".format(PG_USER), yml)
    yml = indentPrint("POSTGRES_DB: {}".format(PG_DB), yml)
    yml = indentPrint("SSH_ENABLE: 1", yml)
    yml = indentPrint("BACKUP_SCHEDULE: \"*/30 */5 * * *\"", yml)
    yml = indentPrint("volumes:", yml)
    yml = indentPrint("- barman:/var/backups", yml)
    yml = indentPrint("- ./ssh:/tmp/.ssh/keys", yml)
    yml = indentPrint("networks:", yml)
    yml = indentPrint("cluster:", yml)
    yml = indentPrint("aliases:", yml)
    yml = indentPrint("- backup", yml)

    yml = indentPrint("", yml)
    resetIndent(2)
    return yml


def printPgPool(yml):
    yml = indentPrint("pgpool:", yml)
    yml = indentPrint("build:", yml)
    yml = indentPrint("context: ../src", yml)
    yml = indentPrint("dockerfile: Pgpool-{}-Postgres-{}.Dockerfile".format(PGPOOL_VERSION, PG_VERSION), yml)
    yml = indentPrint("environment:", yml)
    yml = indentPrint("PCP_USER: {}".format(PCP_USER), yml)
    yml = indentPrint("PCP_PASSWORD: {}".format(PCP_PASSWORD), yml)
    yml = indentPrint("WAIT_BACKEND_TIMEOUT: 60", yml)

    yml = indentPrint("CHECK_USER: {}".format(PG_USER), yml)
    yml = indentPrint("CHECK_PASSWORD: {}".format(PG_PASSWORD), yml)
    yml = indentPrint("CHECK_PGCONNECT_TIMEOUT: 3", yml)
    yml = indentPrint("SSH_ENABLE: 1", yml)
    yml = indentPrint("DB_USERS: {}:{}".format(PG_USER, PG_PASSWORD), yml)
    
    masters = []
    for mid in range(0,N_MASTERS):
        masters.append("pgmaster{}".format(mid))

    slaves = []
    for rid in range(0,N_REPLICAS):
        slaves.append("pgslave{}-0".format(rid))  # Only the first slave of each group

    backends = []
    for i, hostname in enumerate(masters+slaves):
        backends.append("{}:{}:5432:1::".format(i, hostname))

    for rep_group_id in range(0,N_REPLICAS):
        for slave_id in range(1,REPLICA_SIZE):
            backends.append("{}:{}:5432:2::".format(i, "pgslave{}-{}".format(rep_group_id, slave_id)))

    yml = indentPrint("BACKENDS: \"{}\"".format(','.join(backends)), yml)
    
    yml = indentPrint("REQUIRE_MIN_BACKENDS: {}".format(N_MASTERS+N_REPLICAS), yml)
    yml = indentPrint("CONFIGS: \"num_init_children:250,max_pool:4\"", yml)
    yml = indentPrint("ports:", yml)
    yml = indentPrint("- 5432:5432", yml)
    yml = indentPrint("- 9898:9898 # PCP", yml)
    yml = indentPrint("volumes:", yml)
    yml = indentPrint("- ./ssh:/tmp/.ssh/keys", yml)
    yml = indentPrint("networks:", yml)
    yml = indentPrint("cluster:", yml)
    yml = indentPrint("aliases:", yml)
    yml = indentPrint("- pgpool", yml)

    yml = indentPrint("", yml)
    resetIndent(2)
    return yml

try:
    import networkx as nx
    import matplotlib.pyplot as plt
    import netwulf as nw

    def getGraphRepresentation():
        masters = ["pgmaster{}".format(i) for i in range(N_MASTERS)]
        
        main_slaves = ["pgslave{}-0".format(i) for i in range(N_REPLICAS)]
        master_links = [("pgmaster{}".format((10 * i + 1000) %  N_MASTERS), "pgslave{}-0".format(i)) for i in range(N_REPLICAS)]
        
        secondary_slaves = []
        secondary_links = []
        for rep_group_id in range(0,N_REPLICAS):
            for slave_id in range(1,REPLICA_SIZE):
                secondary_slaves.append("pgslave{}-{}".format(rep_group_id, slave_id))
                secondary_links.append(("pgslave{}-0".format(rep_group_id), "pgslave{}-{}".format(rep_group_id, slave_id)))
        
        utilities = ["pgpool", "barman"]
        utilities_links = [("pgmaster0", "barman")] + [("pgpool", "pgmaster{}".format(i)) for i in range(N_MASTERS)]  
        pgpool_links = [("pgpool", "pgslave{}-0".format(i)) for i in range(N_REPLICAS)]

        G=nx.DiGraph()
        G.add_nodes_from(masters, size = 18)
        G.add_nodes_from(utilities, size = 18)
        G.add_nodes_from(main_slaves, size = 8)
        G.add_nodes_from(secondary_slaves, size = 2)
        G.add_edges_from(master_links, weight=4)
        G.add_edges_from(secondary_links, weight=2)
        G.add_edges_from(utilities_links, weight=1)
        # nx.draw(G, with_labels=True, pos=nx.spring_layout(G, k=0.25, iterations=50))
        pos = nx.spring_layout(G, iterations=43)
        nx.draw_networkx_nodes(G, pos, nodelist=masters, cmap=plt.get_cmap('jet'), node_color = '#0064a5', node_size = 1000)
        nx.draw_networkx_nodes(G, pos, nodelist=utilities, cmap=plt.get_cmap('jet'), node_color = '#336791', node_size = [1500, 700])
        nx.draw_networkx_nodes(G, pos, nodelist=main_slaves, cmap=plt.get_cmap('jet'), node_color = '#008bb9', node_size = 500)
        nx.draw_networkx_nodes(G, pos, nodelist=secondary_slaves, cmap=plt.get_cmap('jet'), node_color = '#005996', node_size = 200)
        nx.draw_networkx_labels(G, pos)
        nx.draw_networkx_edges(G, pos, edgelist=master_links, arrows=False, style='dashed')
        nx.draw_networkx_edges(G, pos, edgelist=secondary_links, arrows=True)
        nx.draw_networkx_edges(G, pos, edgelist=utilities_links, arrows=True)
        nx.draw_networkx_edges(G, pos, edgelist=pgpool_links, arrows=True)

        nw.visualize(G)
except:
    print("Some modules required for network representation were not found. Skipping!")
    

if __name__ == "__main__":

    parser = argparse.ArgumentParser(description='Programmatically create postgres docker-compose files with masters, slaves, pgpool and barman.')
    parser.add_argument('-c', '--config', help="Configuration file")
    parser.add_argument('-b', '--barman', action='store_true', help="Enable or disable barman backup manager")
    args = parser.parse_args()

    if args.config:
        config = open(args.config)
    else:
        config = open('docker-compose/autoconf/settings.template.json')
    data = json.load(config) 

    PG_VERSION = data["PG_VERSION"] if "PG_VERSION" in data else 11
    REPMGR_VERSION = data["REPMGR_VERSION"] if "REPMGR_VERSION" in data else 4.0
    PGPOOL_VERSION = data["PGPOOL_VERSION"] if "PGPOOL_VERSION" in data else 3.7
    BARMAN_VERSION = data["BARMAN_VERSION"] if "BARMAN_VERSION" in data else 2.4

    N_MASTERS = int(data["N_MASTERS"]) if "N_MASTERS" in data else 1
    N_REPLICAS = int(data["N_REPLICAS"]) if "N_REPLICAS" in data else 3
    REPLICA_SIZE = int(data["REPLICA_SIZE"]) if "REPLICA_SIZE" in data else 2

    PG_DB = data["PG_DB"] if "PG_DB" in data else "monkey_db"
    PG_USER = data["PG_USER"] if "PG_USER" in data else "monkey_user"
    PG_PASSWORD = data["PG_PASSWORD"] if "PG_PASSWORD" in data else "monkey_pass"

    REP_DB = data["REP_DB"] if "REP_DB" in data else "replication_db"
    REP_USER = data["REP_USER"] if "REP_USER" in data else "replication_user"
    REP_PASSWORD = data["REP_PASSWORD"] if "REP_PASSWORD" in data else "replication_pass"

    PCP_USER = data["PCP_USER"] if "PCP_USER" in data else "pcp_user"
    PCP_PASSWORD = data["PCP_PASSWORD"] if "PCP_PASSWORD" in data else "pcp_pass"

    original_stdout = sys.stdout

    with open('test.yml', 'w') as f:
        sys.stdout = f
        yml = ''
        yml = printHeader(yml)
        yml = printNetworks(yml)
        yml = printVolumes(yml)
        
        yml = indentPrint("services:", yml)
        yml = printMasters(yml)
        yml = printSlaves(yml)

        if args.barman:
            yml = printBarmanBackup(yml)
        
        yml = printPgPool(yml)

        print(yml)

        sys.stdout = original_stdout