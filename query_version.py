#!/usr/bin/env python3
"""
Simple Python script to query Danfysik SYS8X00 power supply version
Supports both serial and TCP/IP communication
"""

import argparse
import sys
import time

def query_version_serial(port, baudrate=9600, timeout=2.0, addr=None):
    """Query version via serial connection"""
    try:
        import serial
    except ImportError:
        print("Error: pyserial not installed. Install with: pip install pyserial")
        return None

    try:
        # Open serial connection
        ser = serial.Serial(
            port=port,
            baudrate=baudrate,
            bytesize=serial.EIGHTBITS,
            parity=serial.PARITY_NONE,
            stopbits=serial.STOPBITS_ONE,
            timeout=timeout
        )

        # Address the power supply if specified
        if addr is not None:
            addr_str = f"{addr:02d}"  # Zero-pad to 2 digits
            ser.write(f"ADR {addr_str}\r".encode())
            # Wait a bit for the command to be processed
            time.sleep(0.1)

        # Send VER command
        ser.write(b"VER\r")

        # Read response (terminated by LF CR)
        response = ser.read_until(b'\r').decode('ascii').strip()

        ser.close()
        return response

    except Exception as e:
        print(f"Serial communication error: {e}")
        return None

def scan_addresses(connection_type, connection_params, timeout=2.0):
    """Scan a range of addresses to find responding power supplies"""
    responding_addrs = []
    
    if connection_type == 'serial':
        port, baudrate = connection_params
        for addr in range(64):  # 0-63
            print(f"Testing address {addr:02d}...", end=' ', flush=True)
            response = query_version_serial(port, baudrate, timeout, addr)
            if response:
                print(f"✓ (Response: {response})")
                responding_addrs.append((addr, response))
            else:
                print("✗")
    
    elif connection_type == 'tcp':
        host, port_num = connection_params
        for addr in range(64):  # 0-63
            print(f"Testing address {addr:02d}...", end=' ', flush=True)
            response = query_version_tcp(host, port_num, timeout, addr)
            if response:
                print(f"✓ (Response: {response})")
                responding_addrs.append((addr, response))
            else:
                print("✗")
    
    return responding_addrs

def query_version_tcp(host, port_num, timeout=2.0, addr=None):
    """Query version via TCP/IP connection"""
    import socket

    try:
        # Create socket
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(timeout)

        # Connect
        sock.connect((host, port_num))

        # Address the power supply if specified
        if addr is not None:
            addr_str = f"{addr:02d}"  # Zero-pad to 2 digits
            sock.send(f"ADR {addr_str}\r".encode())
            # Wait a bit for the command to be processed
            time.sleep(0.1)

        # Send VER command
        sock.send(b"VER\r")

        # Read response
        response = sock.recv(1024).decode('ascii').strip()

        sock.close()
        return response

    except Exception as e:
        print(f"TCP communication error: {e}")
        return None

def scan_addresses(connection_type, connection_params, timeout=2.0):
    """Scan a range of addresses to find responding power supplies"""
    responding_addrs = []
    
    if connection_type == 'serial':
        port, baudrate = connection_params
        for addr in range(64):  # 0-63
            print(f"Testing address {addr:02d}...", end=' ', flush=True)
            response = query_version_serial(port, baudrate, timeout, addr)
            if response:
                print(f"✓ (Response: {response})")
                responding_addrs.append((addr, response))
            else:
                print("✗")
    
    elif connection_type == 'tcp':
        host, port_num = connection_params
        for addr in range(64):  # 0-63
            print(f"Testing address {addr:02d}...", end=' ', flush=True)
            response = query_version_tcp(host, port_num, timeout, addr)
            if response:
                print(f"✓ (Response: {response})")
                responding_addrs.append((addr, response))
            else:
                print("✗")
    
    return responding_addrs

def main():
    parser = argparse.ArgumentParser(description='Query Danfysik SYS8X00 version')
    parser.add_argument('--serial', '-s', help='Serial port (e.g., /dev/ttyUSB0)')
    parser.add_argument('--baudrate', '-b', type=int, default=9600,
                       help='Serial baudrate (default: 9600)')
    parser.add_argument('--tcp', '-t', help='TCP host:port (e.g., 192.168.1.100:4001)')
    parser.add_argument('--addr', '-a', type=int, help='Power supply address (0-63)')
    parser.add_argument('--scan', action='store_true', help='Scan all addresses (0-63) to find responding power supplies')
    parser.add_argument('--timeout', type=float, default=2.0,
                       help='Communication timeout in seconds (default: 2.0)')

    args = parser.parse_args()

    if not args.serial and not args.tcp:
        print("Error: Must specify either --serial or --tcp")
        parser.print_help()
        sys.exit(1)

    if args.scan:
        # Scan mode - find all responding addresses
        if args.serial:
            print(f"Scanning all addresses via serial: {args.serial} at {args.baudrate} baud")
            connection_params = (args.serial, args.baudrate)
            responding = scan_addresses('serial', connection_params, args.timeout)
        elif args.tcp:
            try:
                host, port_str = args.tcp.split(':')
                port_num = int(port_str)
                print(f"Scanning all addresses via TCP: {host}:{port_num}")
                connection_params = (host, port_num)
                responding = scan_addresses('tcp', connection_params, args.timeout)
            except ValueError:
                print("Error: TCP argument must be in format host:port")
                sys.exit(1)
        
        print(f"\nScan complete. Found {len(responding)} responding power supplies:")
        for addr, response in responding:
            print(f"  Address {addr:02d}: {response}")
        
        if not responding:
            print("  No power supplies responded.")
            sys.exit(1)
            
    else:
        # Single query mode
        response = None

        if args.serial:
            print(f"Querying version via serial: {args.serial} at {args.baudrate} baud")
            if args.addr is not None:
                print(f"Addressing power supply: {args.addr}")
            response = query_version_serial(args.serial, args.baudrate, args.timeout, args.addr)

        elif args.tcp:
            try:
                host, port_str = args.tcp.split(':')
                port_num = int(port_str)
                print(f"Querying version via TCP: {host}:{port_num}")
                if args.addr is not None:
                    print(f"Addressing power supply: {args.addr}")
                response = query_version_tcp(host, port_num, args.timeout, args.addr)
            except ValueError:
                print("Error: TCP argument must be in format host:port")
                sys.exit(1)

        if response:
            print(f"Version response: {response}")
        else:
            print("Failed to get version response")
            sys.exit(1)

if __name__ == "__main__":
    main()