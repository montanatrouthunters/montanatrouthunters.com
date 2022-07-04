#!/usr/bin/env bash

HUGOxPARAMSxCMSxLOCAL_BACKEND=true \
HUGO_MODULE_REPLACEMENTS="github.com/shoginn/wowchemy-widgets/widgets/pricing-cards -> ../../wowchemy-widgets/widgets/pricing-cards,
github.com/shoginn/wowchemy-widgets/widgets/instagram-behold -> ../../wowchemy-widgets/widgets/instagram-behold" \
hugo server --panicOnWarning --renderStaticToDisk --buildFuture