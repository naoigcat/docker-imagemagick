#!/usr/bin/env bash
set -euo pipefail

dockerfile=${1:-Dockerfile}
temporary_directory=$(mktemp -d)
trap 'rm -rf "$temporary_directory"' EXIT

awk_start=$(grep -n '^    awk' "$dockerfile" | head -n1 | cut -d: -f1)
awk_end=$(grep -n 'tmp_file";' "$dockerfile" | head -n1 | cut -d: -f1)
awk_program=$(sed -n "$((awk_start + 1)),$((awk_end - 1))p" "$dockerfile" | sed 's/[[:space:]]*\\$//')

valid_policy="$temporary_directory/valid-policy.xml"
missing_end_policy="$temporary_directory/missing-end-policy.xml"
duplicate_end_policy="$temporary_directory/duplicate-end-policy.xml"
same_line_duplicate_policy="$temporary_directory/same-line-duplicate-policy.xml"
comment_only_policy="$temporary_directory/comment-only-policy.xml"
output_policy="$temporary_directory/output-policy.xml"

required_policies=(
    'domain="resource" name="memory" value="512MiB"'
    'domain="resource" name="map" value="1GiB"'
    'domain="resource" name="disk" value="2GiB"'
    'domain="resource" name="area" value="128MP"'
    'domain="resource" name="time" value="120"'
    'domain="resource" name="thread" value="4"'
    'domain="path" rights="none" pattern="@*"'
    'domain="delegate" rights="none" pattern="URL"'
    'domain="delegate" rights="none" pattern="HTTP"'
    'domain="delegate" rights="none" pattern="HTTPS"'
    'domain="coder" rights="none" pattern="PDF"'
    'domain="coder" rights="none" pattern="PS"'
    'domain="coder" rights="none" pattern="PS2"'
    'domain="coder" rights="none" pattern="PS3"'
    'domain="coder" rights="none" pattern="EPS"'
    'domain="coder" rights="none" pattern="XPS"'
)

existing_policy='  <policy domain="resource" name="existing" value="keep"/>'
printf '%s\n' '<policymap>' "$existing_policy" '</policymap>' > "$valid_policy"
printf '%s\n' '<policymap>' "$existing_policy" > "$missing_end_policy"
printf '%s\n' '<policymap>' "$existing_policy" '</policymap>' '</policymap>' > "$duplicate_end_policy"
printf '%s\n' '<policymap></policymap>' > "$same_line_duplicate_policy"
printf '%s\n' '<!-- </policymap> -->' > "$comment_only_policy"

awk "$awk_program" "$valid_policy" > "$output_policy"
grep -Fq "$existing_policy" "$output_policy"
for required_policy in "${required_policies[@]}"
do
    grep -Fq "$required_policy" "$output_policy"
done

if awk "$awk_program" "$missing_end_policy" > /dev/null
then
    printf 'A policy without </policymap> must fail validation\n' >&2
    exit 1
fi

if awk "$awk_program" "$duplicate_end_policy" > /dev/null
then
    printf 'A policy with multiple </policymap> tags must fail validation\n' >&2
    exit 1
fi

if awk "$awk_program" "$same_line_duplicate_policy" > /dev/null
then
    printf 'Multiple </policymap> tags on one line must fail validation\n' >&2
    exit 1
fi

if awk "$awk_program" "$comment_only_policy" > /dev/null
then
    printf 'A comment containing </policymap> must not pass validation\n' >&2
    exit 1
fi

policy_block=$(sed -n "$(grep -n '^RUN set -eux;' "$dockerfile" | head -n1 | cut -d: -f1),$(grep -n '^RUN ldconfig' "$dockerfile" | head -n1 | cut -d: -f1)p" "$dockerfile")
grep -Fq 'MAGICK_CONFIGURE_PATH="$validation_directory" magick -list policy' <<< "$policy_block"
grep -Fq 'grep -Fq "$required_policy" "$tmp_file"' <<< "$policy_block"

validation_line=$(grep -nF 'policy_list=' <<< "$policy_block" | head -n1 | cut -d: -f1)
required_check_line=$(grep -nF 'grep -Fq "$required_policy" "$tmp_file"' <<< "$policy_block" | head -n1 | cut -d: -f1)
commit_line=$(grep -nF 'install -m 0644 "$tmp_file" "$policy_file"' <<< "$policy_block" | head -n1 | cut -d: -f1)
if (( validation_line >= required_check_line || required_check_line >= commit_line ))
then
    printf 'The original policy must not be replaced before staged validation succeeds\n' >&2
    exit 1
fi

for required_policy in "${required_policies[@]}"
do
    grep -Fq "$required_policy" <<< "$policy_block"
done

printf 'ImageMagick policy insertion validates its boundary and final policy set\n'
