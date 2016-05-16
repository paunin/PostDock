#!/bin/bash

echo ">>> Waiting $CLUSTER_NODE_REGISTER_DELAY seconds to register node with initial role $INITIAL_NODE_TYPE"
(sleep $CLUSTER_NODE_REGISTER_DELAY && \
echo ">>> Registering node with initial role $INITIAL_NODE_TYPE"
gosu postgres repmgr $INITIAL_NODE_TYPE register) &