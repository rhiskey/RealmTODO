//
//  TaskListsViewController.swift
//  RealmApp
//
//  Created by Alexey Efimov on 02.07.2018.
//  Copyright © 2018 Alexey Efimov. All rights reserved.
//

import RealmSwift
import UIKit

class TaskListViewController: UITableViewController {
    
    private var taskLists: Results<TaskList>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createTempData()
        taskLists = StorageManager.shared.realm.objects(TaskList.self)
        navigationItem.leftBarButtonItem = editButtonItem
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        taskLists.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskListCell", for: indexPath)
        let taskList = taskLists[indexPath.row]
        var content = cell.defaultContentConfiguration()
        
        content.text = taskList.name
        
        let taskCount = decideHowToRepresentTaskCounter(for: taskList)
        
        if taskCount == -1 {
            cell.accessoryType = .checkmark
        } else {
            content.secondaryText = "\(taskCount)"
            cell.accessoryType = .none
        }
        
        cell.contentConfiguration = content
        return cell
    }
    
    // MARK: - UITableViewDelegate
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let taskList = taskLists[indexPath.row]
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { _, _, _ in
            StorageManager.shared.delete(taskList)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
        
        let editAction = UIContextualAction(style: .normal, title: "Edit") { _, _, isDone in
            self.showAlert(with: taskList) {
                tableView.reloadRows(at: [indexPath], with: .automatic)
            }
            isDone(true)
        }
        
        let doneAction = UIContextualAction(style: .normal, title: "Done") {_, _, isDone in
            StorageManager.shared.done(taskList)
            tableView.reloadRows(at: [indexPath], with: .automatic)
            
            isDone(true)
        }
        
        editAction.backgroundColor = .orange
        doneAction.backgroundColor = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
        
        return UISwipeActionsConfiguration(actions: [doneAction, editAction, deleteAction])
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let indexPath = tableView.indexPathForSelectedRow else { return }
        guard let tasksVC = segue.destination as? TasksViewController else { return }
        let taskList = taskLists[indexPath.row]
        tasksVC.taskList = taskList
    }
    
    @IBAction func  addButtonPressed(_ sender: Any) {
        showAlert()
    }
    
    // MARK: - Sorting using Realm
    @IBAction func sortingList(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex{
        case 0:
            // sort tasks by date
            taskLists = StorageManager.shared.realm.objects(TaskList.self).sorted(byKeyPath: "date", ascending: false)
            tableView.reloadData()
            break
        default:
            // sort tasks by a-z
            taskLists = StorageManager.shared.realm.objects(TaskList.self).sorted(byKeyPath: "name", ascending: true)
            tableView.reloadData()
            break
        }
    }
    
    private func createTempData() {
        DataManager.shared.createTempData {
            self.tableView.reloadData()
        }
    }
    
}

extension TaskListViewController {
    private func showAlert(with taskList: TaskList? = nil, completion: (() -> Void)? = nil) {
        let alert = AlertController.createAlert(withTitle: "New List", andMessage: "Please insert new value")
        
        alert.action(with: taskList) { newValue in
            if let taskList = taskList, let completion = completion {
                StorageManager.shared.edit(taskList, newValue: newValue)
                completion()
            } else {
                self.save(newValue)
            }
        }
        
        present(alert, animated: true)
    }
    
    private func save(_ taskList: String) {
        let taskList = TaskList(value: [taskList])
        StorageManager.shared.save(taskList)
        let rowIndex = IndexPath(row: taskLists.index(of: taskList) ?? 0, section: 0)
        tableView.insertRows(at: [rowIndex], with: .automatic)
    }
    
}

// MARK: - Task Representation (not optimal)
extension TaskListViewController {
    private func decideHowToRepresentTaskCounter(for taskList: TaskList) -> Int {
        var taskCount = 0
        
        if taskList.tasks.count == 0 {
            taskCount = 0
        } else {
            var currentTasksCounter = 0
            var completedCounter = 0
            
            for task in taskList.tasks {
                if !task.isComplete {
                    currentTasksCounter += 1
                } else {
                    completedCounter += 1
                }
            }
            
            if completedCounter > 0 && currentTasksCounter == 0 {
                taskCount = -1
            } else {
                taskCount = currentTasksCounter
            }
        }
        return taskCount
    }
}
