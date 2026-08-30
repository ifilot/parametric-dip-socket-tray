#!/usr/bin/env bash
# SPDX-License-Identifier: CERN-OHL-S-2.0

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
project_root="$(cd -- "${script_dir}/.." && pwd)"
output_dir="${1:-${project_root}/build}"

if [[ "${output_dir}" != /* ]]; then
    output_dir="${project_root}/${output_dir}"
fi

mkdir -p "${output_dir}"

pins=(14 16 18 20 28 32 40)
parts=(tray label fit_test)

for pin_count in "${pins[@]}"; do
    for part_name in "${parts[@]}"; do
        file_part="${part_name}"
        if [[ "${part_name}" == "fit_test" ]]; then
            file_part="fit-test"
        fi

        output_file="${output_dir}/dip${pin_count}-${file_part}.stl"
        echo "Building ${output_file#"${project_root}/"}"
        openscad \
            -o "${output_file}" \
            -D "pins=${pin_count}" \
            -D "part=\"${part_name}\"" \
            "${project_root}/dip_socket_tray.scad"
    done
done

echo "Built $(( ${#pins[@]} * ${#parts[@]} )) STL files in ${output_dir}"
