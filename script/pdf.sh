#!/bin/bash
# SPDX-License-Identifier: CC0-1.0
# SPDX-FileCopyrightText: 2021-2022 The Foundation for Public Code <info@publiccode.net>, https://standard.publiccode.net/AUTHORS

# This script is used to generate a PDF from the html generated by Jekyll.
# This script is used during the release process (see ../docs/releasing.md)

# if a parameter is passed to the script, then it will be used as the
# pre-release identifier
if [ "_${1}_" != "__" ]; then
PRE_RELEASE_ID="-${1}"
else
PRE_RELEASE_ID=""
fi

# grep to extract version line from _config.yml,
# cut to take just the content after the colon
# xargs to strip the leading space
# and add the pre-release-identifier if any
VERSION=$(grep version _config.yml | cut -f2 -d':' | xargs)$PRE_RELEASE_ID;

JEKYLL_PDF_PORT=9000
JEKYLL_PDF_DIR=_build_pdf
rm -rf $JEKYLL_PDF_DIR

PAGES_REPO_NWO=publiccodenet/standard \
	bundle exec jekyll serve \
		--port=$JEKYLL_PDF_PORT \
		--destination=$JEKYLL_PDF_DIR &
JEKYLL_PID=$!
function cleanup() {
	echo "Killing JEKYLL_PID: $JEKYLL_PID"
	kill $JEKYLL_PID
}
trap cleanup EXIT # stop the jekyll serve

MAX_LOOPS=100
LOOPS=0
while ! curl "http://localhost:$JEKYLL_PDF_PORT" >/dev/null 2>&1 ; do
	LOOPS=$(( $LOOPS + 1 ));
	echo "try $LOOPS, waiting to connect ..."
	sleep 1;
	if [ $LOOPS -gt $MAX_LOOPS ]; then
		echo "exceeds MAX_LOOPS";
		exit 1;
	fi
done

# give it one more second
sleep 1;

weasyprint --presentational-hints \
	"http://localhost:$JEKYLL_PDF_PORT/print.html" \
	standard-$VERSION.pdf
ls -l standard-$VERSION.pdf

weasyprint --presentational-hints \
	"http://localhost:$JEKYLL_PDF_PORT/print-cover.html" \
	standard-cover-$VERSION.pdf
ls -l standard-cover-$VERSION.pdf

weasyprint --presentational-hints \
	"http://localhost:$JEKYLL_PDF_PORT/print-review-template.html" \
	review-template-$VERSION.pdf
ls -l review-template-$VERSION.pdf

echo "done"
