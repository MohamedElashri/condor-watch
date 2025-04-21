# condor-watch

A lightweight, cron-compatible HTCondor job monitoring tool.

## Features

- Monitor one or multiple HTCondor job IDs
- Get email notifications on status changes
- Fully configurable via a single config file
- Works on CERN lxplus or any HTCondor user machine
- Relies solely on `msmtp` for outbound mail
- Cron-friendly and does not require root

## Configuration

Edit `condor-watch.conf` to specify:
- Job IDs to monitor
- Email settings (sender, receiver, subject)
- Notification level (on every check or only on changes)

## Email Delivery with `msmtp`

This tool **only supports** sending email via [`msmtp`](https://marlam.de/msmtp/), a lightweight SMTP relay tool.

### ✅ Step 1: Install `msmtp` locally

#### Option A: From Conda (preferred on lxplus)

```bash
conda install -c conda-forge msmtp
```

Make sure the installed binary is on your `$PATH`.

#### Option B: Manual build in `$HOME`

```bash
mkdir -p ~/opt/msmtp && cd ~/opt
wget https://marlam.de/msmtp/releases/msmtp-1.8.24.tar.xz
tar -xf msmtp-1.8.24.tar.xz && cd msmtp-1.8.24
./configure --prefix=$HOME/opt/msmtp-install
make && make install
export PATH="$HOME/opt/msmtp-install/bin:$PATH"
```

### ✅ Step 2: Create a secure `.msmtprc`

```bash
cat > ~/.msmtprc <<EOF
defaults
auth on
tls on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile ~/.msmtp.log

account gmail
host smtp.gmail.com
port 587
from your-email@gmail.com
user your-email@gmail.com
passwordeval "gpg --quiet --for-your-eyes-only --no-tty --decrypt ~/.gmail.gpg"
account default : gmail
EOF

chmod 600 ~/.msmtprc
```

Use an [App Password](https://support.google.com/accounts/answer/185833) from Gmail. Store it encrypted:

```bash
echo "your-app-password" | gpg --symmetric --output ~/.gmail.gpg
```

### ✅ Step 3: Test `msmtp`

```bash
echo "Test from condor-watch" | msmtp -s "Test Email" your-email@gmail.com
```

If this works, `condor-watch` is ready to send alerts.

## Usage

1. Clone the repo and configure `condor-watch.conf`:
   ```bash
   git clone https://github.com/MohamedElashri/condor-watch
   ```

2. Make the script executable:
   ```bash
   chmod +x condor-watch.sh
   ```

3. Test run:
   ```bash
   ./condor-watch.sh
   ```

4. Add to cron:
   ```bash
   crontab -e
   ```

   Example (run every 10 mins):
   ```
   */10 * * * * /path/to/condor-watch/condor-watch.sh
   ```

## Dependencies

- `condor_q` (part of HTCondor)
- `msmtp` (must be manually installed by the user)

## Security

Never commit `.msmtprc`, `.gmail.gpg`, or any credential-related files to version control.

