#!/usr/bin/env python3
import argparse
import json
import os
import sys

TASKS_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "tasks.json")

class TaskManager:
    def __init__(self):
        self.data = self.load_data()

    def load_data(self):
        if os.path.exists(TASKS_FILE):
            try:
                with open(TASKS_FILE, "r") as f:
                    content = json.load(f)
                    if isinstance(content, list):
                        return {"Default": [{"title": t, "due": ""} for t in content]}
                    return content
            except Exception:
                pass
        return {"Default": []}

    def save_data(self):
        os.makedirs(os.path.dirname(TASKS_FILE), exist_ok=True)
        with open(TASKS_FILE, "w") as f:
            json.dump(self.data, f, indent=4)

    def create_folder(self, folder_name):
        folder_name = folder_name.strip()
        if folder_name and folder_name not in self.data:
            self.data[folder_name] = []
            self.save_data()
            return f"Folder created: {folder_name}"
        return "Folder already exists or invalid"

    def remove_folder(self, folder_name):
        if folder_name in self.data:
            del self.data[folder_name]
            # Always ensure at least one folder exists
            if not self.data:
                self.data["Default"] = []
            self.save_data()
            return f"Folder removed: {folder_name}"
        return "Error: Folder does not exist"

    def create_task(self, title, folder="Default", due=""):
        if folder not in self.data:
            self.data[folder] = []
        self.data[folder].append({"title": title, "due": due})
        self.save_data()
        return f"Task added to [{folder}]: {title}"

    def remove_task(self, index, folder="Default"):
        if folder in self.data and 0 <= index < len(self.data[folder]):
            removed = self.data[folder].pop(index)
            self.save_data()
            return f"Removed: {removed['title']}"
        return "Error: Invalid index"

    def export_json(self):
        return json.dumps(self.data)

def main():
    manager = TaskManager()
    parser = argparse.ArgumentParser()
    parser.add_argument('-c', '--command', choices=['create', 'remove', 'create-folder', 'remove-folder', 'export-json'], required=True)
    parser.add_argument('-f', '--folder', default='Default')
    parser.add_argument('-t', '--title', default='')
    parser.add_argument('-d', '--due', default='')
    parser.add_argument('-i', '--index', type=int, default=-1)

    args = parser.parse_args()

    if args.command == 'create':
        if not args.title:
            sys.exit(1)
        print(manager.create_task(args.title, args.folder, args.due))
    elif args.command == 'create-folder':
        print(manager.create_folder(args.folder))
    elif args.command == 'remove-folder':
        print(manager.remove_folder(args.folder))
    elif args.command == 'remove':
        if args.index < 0:
            sys.exit(1)
        print(manager.remove_task(args.index, args.folder))
    elif args.command == 'export-json':
        print(manager.export_json())

if __name__ == "__main__":
    main()
