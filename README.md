# Local Network Scanner

A bash script that scans your local network for active hosts and retrieves detailed ARP table entries, presenting the results in a clean, formatted table.

## Versions

**Current version**: 0.1.0

- Initial release with basic network scanning and ARP table processing functionality

## Table of Contents

- [Versions](#versions)
- [Badges](#badges)
- [Installation](#installation)
- [Usage](#usage)
- [License](#license)
- [Contributing](#contributing)

## Badges

![Bash](https://img.shields.io/badge/Bash-5.0%2B-green)
![Version](https://img.shields.io/badge/Version-0.1.0-blue)
![License](https://img.shields.io/badge/License-MIT-yellow)

## Installation

1. Clone the repository or download the script:

   ```bash
   git clone https://github.com/beecave-homelab/scan-local-network.git
   ```

2. Make the script executable:

   ```bash
   chmod +x scan-local-network.sh
   ```

3. Ensure you have the required dependencies:
   - bash (5.0+)
   - ping
   - arp
   - scutil (for macOS)

## Usage

Run the script directly:

```bash
./scan-local-network.sh
```

Options:

- `-h, --help`: Display help message

The script will:

1. Scan your local network subnet for active hosts
2. Process and display the ARP table entries in a formatted table with:
   - MAC addresses
   - Interface names
   - Hostnames
   - IP addresses

## License

This project is licensed under the MIT license. See [LICENSE](LICENSE) for more information.

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.
