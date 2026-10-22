part of 'generated.dart';

class OperationsVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  OperationsVariablesBuilder(this._dataConnect, );
  Deserializer<OperationsData> dataDeserializer = (dynamic json)  => OperationsData.fromJson(jsonDecode(json));
  
  Future<OperationResult<OperationsData, void>> execute() {
    return ref().execute();
  }

  MutationRef<OperationsData, void> ref() {
    
    return _dataConnect.mutation("Operations", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class OperationsDepartmentInsert {
  final String id;
  OperationsDepartmentInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final OperationsDepartmentInsert otherTyped = other as OperationsDepartmentInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  OperationsDepartmentInsert({
    required this.id,
  });
}

@immutable
class OperationsDepartmentUpdate {
  final String id;
  OperationsDepartmentUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final OperationsDepartmentUpdate otherTyped = other as OperationsDepartmentUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  OperationsDepartmentUpdate({
    required this.id,
  });
}

@immutable
class OperationsDepartmentDelete {
  final String id;
  OperationsDepartmentDelete.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final OperationsDepartmentDelete otherTyped = other as OperationsDepartmentDelete;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  OperationsDepartmentDelete({
    required this.id,
  });
}

@immutable
class OperationsEmployeeInsert {
  final String id;
  OperationsEmployeeInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final OperationsEmployeeInsert otherTyped = other as OperationsEmployeeInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  OperationsEmployeeInsert({
    required this.id,
  });
}

@immutable
class OperationsEmployeeUpdate {
  final String id;
  OperationsEmployeeUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final OperationsEmployeeUpdate otherTyped = other as OperationsEmployeeUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  OperationsEmployeeUpdate({
    required this.id,
  });
}

@immutable
class OperationsEmployeeDelete {
  final String id;
  OperationsEmployeeDelete.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final OperationsEmployeeDelete otherTyped = other as OperationsEmployeeDelete;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  OperationsEmployeeDelete({
    required this.id,
  });
}

@immutable
class OperationsManagerInsert {
  final String id;
  OperationsManagerInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final OperationsManagerInsert otherTyped = other as OperationsManagerInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  OperationsManagerInsert({
    required this.id,
  });
}

@immutable
class OperationsManagerUpdate {
  final String id;
  OperationsManagerUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final OperationsManagerUpdate otherTyped = other as OperationsManagerUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  OperationsManagerUpdate({
    required this.id,
  });
}

@immutable
class OperationsManagerDelete {
  final String id;
  OperationsManagerDelete.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final OperationsManagerDelete otherTyped = other as OperationsManagerDelete;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  OperationsManagerDelete({
    required this.id,
  });
}

@immutable
class OperationsAssignmentInsert {
  final String id;
  OperationsAssignmentInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final OperationsAssignmentInsert otherTyped = other as OperationsAssignmentInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  OperationsAssignmentInsert({
    required this.id,
  });
}

@immutable
class OperationsAssignmentUpdate {
  final String id;
  OperationsAssignmentUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final OperationsAssignmentUpdate otherTyped = other as OperationsAssignmentUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  OperationsAssignmentUpdate({
    required this.id,
  });
}

@immutable
class OperationsAssignmentDelete {
  final String id;
  OperationsAssignmentDelete.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final OperationsAssignmentDelete otherTyped = other as OperationsAssignmentDelete;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  OperationsAssignmentDelete({
    required this.id,
  });
}

@immutable
class OperationsSkillInsert {
  final String id;
  OperationsSkillInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final OperationsSkillInsert otherTyped = other as OperationsSkillInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  OperationsSkillInsert({
    required this.id,
  });
}

@immutable
class OperationsSkillUpdate {
  final String id;
  OperationsSkillUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final OperationsSkillUpdate otherTyped = other as OperationsSkillUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  OperationsSkillUpdate({
    required this.id,
  });
}

@immutable
class OperationsSkillDelete {
  final String id;
  OperationsSkillDelete.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final OperationsSkillDelete otherTyped = other as OperationsSkillDelete;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  OperationsSkillDelete({
    required this.id,
  });
}

@immutable
class OperationsEmployeeSkillInsert {
  final String employeeId;
  final String skillId;
  OperationsEmployeeSkillInsert.fromJson(dynamic json):
  
  employeeId = nativeFromJson<String>(json['employeeId']),
  skillId = nativeFromJson<String>(json['skillId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final OperationsEmployeeSkillInsert otherTyped = other as OperationsEmployeeSkillInsert;
    return employeeId == otherTyped.employeeId && 
    skillId == otherTyped.skillId;
    
  }
  @override
  int get hashCode => Object.hashAll([employeeId.hashCode, skillId.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['employeeId'] = nativeToJson<String>(employeeId);
    json['skillId'] = nativeToJson<String>(skillId);
    return json;
  }

  OperationsEmployeeSkillInsert({
    required this.employeeId,
    required this.skillId,
  });
}

@immutable
class OperationsEmployeeSkillUpdate {
  final String employeeId;
  final String skillId;
  OperationsEmployeeSkillUpdate.fromJson(dynamic json):
  
  employeeId = nativeFromJson<String>(json['employeeId']),
  skillId = nativeFromJson<String>(json['skillId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final OperationsEmployeeSkillUpdate otherTyped = other as OperationsEmployeeSkillUpdate;
    return employeeId == otherTyped.employeeId && 
    skillId == otherTyped.skillId;
    
  }
  @override
  int get hashCode => Object.hashAll([employeeId.hashCode, skillId.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['employeeId'] = nativeToJson<String>(employeeId);
    json['skillId'] = nativeToJson<String>(skillId);
    return json;
  }

  OperationsEmployeeSkillUpdate({
    required this.employeeId,
    required this.skillId,
  });
}

@immutable
class OperationsEmployeeSkillDelete {
  final String employeeId;
  final String skillId;
  OperationsEmployeeSkillDelete.fromJson(dynamic json):
  
  employeeId = nativeFromJson<String>(json['employeeId']),
  skillId = nativeFromJson<String>(json['skillId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final OperationsEmployeeSkillDelete otherTyped = other as OperationsEmployeeSkillDelete;
    return employeeId == otherTyped.employeeId && 
    skillId == otherTyped.skillId;
    
  }
  @override
  int get hashCode => Object.hashAll([employeeId.hashCode, skillId.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['employeeId'] = nativeToJson<String>(employeeId);
    json['skillId'] = nativeToJson<String>(skillId);
    return json;
  }

  OperationsEmployeeSkillDelete({
    required this.employeeId,
    required this.skillId,
  });
}

@immutable
class OperationsData {
  final OperationsDepartmentInsert department_insert;
  final OperationsDepartmentUpdate? department_update;
  final OperationsDepartmentDelete? department_delete;
  final OperationsEmployeeInsert employee_insert;
  final OperationsEmployeeUpdate? employee_update;
  final OperationsEmployeeDelete? employee_delete;
  final OperationsManagerInsert manager_insert;
  final OperationsManagerUpdate? manager_update;
  final OperationsManagerDelete? manager_delete;
  final OperationsAssignmentInsert assignment_insert;
  final OperationsAssignmentUpdate? assignment_update;
  final OperationsAssignmentDelete? assignment_delete;
  final OperationsSkillInsert skill_insert;
  final OperationsSkillUpdate? skill_update;
  final OperationsSkillDelete? skill_delete;
  final OperationsEmployeeSkillInsert employeeSkill_insert;
  final OperationsEmployeeSkillUpdate? employeeSkill_update;
  final OperationsEmployeeSkillDelete? employeeSkill_delete;
  OperationsData.fromJson(dynamic json):
  
  department_insert = OperationsDepartmentInsert.fromJson(json['department_insert']),
  department_update = json['department_update'] == null ? null : OperationsDepartmentUpdate.fromJson(json['department_update']),
  department_delete = json['department_delete'] == null ? null : OperationsDepartmentDelete.fromJson(json['department_delete']),
  employee_insert = OperationsEmployeeInsert.fromJson(json['employee_insert']),
  employee_update = json['employee_update'] == null ? null : OperationsEmployeeUpdate.fromJson(json['employee_update']),
  employee_delete = json['employee_delete'] == null ? null : OperationsEmployeeDelete.fromJson(json['employee_delete']),
  manager_insert = OperationsManagerInsert.fromJson(json['manager_insert']),
  manager_update = json['manager_update'] == null ? null : OperationsManagerUpdate.fromJson(json['manager_update']),
  manager_delete = json['manager_delete'] == null ? null : OperationsManagerDelete.fromJson(json['manager_delete']),
  assignment_insert = OperationsAssignmentInsert.fromJson(json['assignment_insert']),
  assignment_update = json['assignment_update'] == null ? null : OperationsAssignmentUpdate.fromJson(json['assignment_update']),
  assignment_delete = json['assignment_delete'] == null ? null : OperationsAssignmentDelete.fromJson(json['assignment_delete']),
  skill_insert = OperationsSkillInsert.fromJson(json['skill_insert']),
  skill_update = json['skill_update'] == null ? null : OperationsSkillUpdate.fromJson(json['skill_update']),
  skill_delete = json['skill_delete'] == null ? null : OperationsSkillDelete.fromJson(json['skill_delete']),
  employeeSkill_insert = OperationsEmployeeSkillInsert.fromJson(json['employeeSkill_insert']),
  employeeSkill_update = json['employeeSkill_update'] == null ? null : OperationsEmployeeSkillUpdate.fromJson(json['employeeSkill_update']),
  employeeSkill_delete = json['employeeSkill_delete'] == null ? null : OperationsEmployeeSkillDelete.fromJson(json['employeeSkill_delete']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final OperationsData otherTyped = other as OperationsData;
    return department_insert == otherTyped.department_insert && 
    department_update == otherTyped.department_update && 
    department_delete == otherTyped.department_delete && 
    employee_insert == otherTyped.employee_insert && 
    employee_update == otherTyped.employee_update && 
    employee_delete == otherTyped.employee_delete && 
    manager_insert == otherTyped.manager_insert && 
    manager_update == otherTyped.manager_update && 
    manager_delete == otherTyped.manager_delete && 
    assignment_insert == otherTyped.assignment_insert && 
    assignment_update == otherTyped.assignment_update && 
    assignment_delete == otherTyped.assignment_delete && 
    skill_insert == otherTyped.skill_insert && 
    skill_update == otherTyped.skill_update && 
    skill_delete == otherTyped.skill_delete && 
    employeeSkill_insert == otherTyped.employeeSkill_insert && 
    employeeSkill_update == otherTyped.employeeSkill_update && 
    employeeSkill_delete == otherTyped.employeeSkill_delete;
    
  }
  @override
  int get hashCode => Object.hashAll([department_insert.hashCode, department_update.hashCode, department_delete.hashCode, employee_insert.hashCode, employee_update.hashCode, employee_delete.hashCode, manager_insert.hashCode, manager_update.hashCode, manager_delete.hashCode, assignment_insert.hashCode, assignment_update.hashCode, assignment_delete.hashCode, skill_insert.hashCode, skill_update.hashCode, skill_delete.hashCode, employeeSkill_insert.hashCode, employeeSkill_update.hashCode, employeeSkill_delete.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['department_insert'] = department_insert.toJson();
    if (department_update != null) {
      json['department_update'] = department_update!.toJson();
    }
    if (department_delete != null) {
      json['department_delete'] = department_delete!.toJson();
    }
    json['employee_insert'] = employee_insert.toJson();
    if (employee_update != null) {
      json['employee_update'] = employee_update!.toJson();
    }
    if (employee_delete != null) {
      json['employee_delete'] = employee_delete!.toJson();
    }
    json['manager_insert'] = manager_insert.toJson();
    if (manager_update != null) {
      json['manager_update'] = manager_update!.toJson();
    }
    if (manager_delete != null) {
      json['manager_delete'] = manager_delete!.toJson();
    }
    json['assignment_insert'] = assignment_insert.toJson();
    if (assignment_update != null) {
      json['assignment_update'] = assignment_update!.toJson();
    }
    if (assignment_delete != null) {
      json['assignment_delete'] = assignment_delete!.toJson();
    }
    json['skill_insert'] = skill_insert.toJson();
    if (skill_update != null) {
      json['skill_update'] = skill_update!.toJson();
    }
    if (skill_delete != null) {
      json['skill_delete'] = skill_delete!.toJson();
    }
    json['employeeSkill_insert'] = employeeSkill_insert.toJson();
    if (employeeSkill_update != null) {
      json['employeeSkill_update'] = employeeSkill_update!.toJson();
    }
    if (employeeSkill_delete != null) {
      json['employeeSkill_delete'] = employeeSkill_delete!.toJson();
    }
    return json;
  }

  OperationsData({
    required this.department_insert,
    this.department_update,
    this.department_delete,
    required this.employee_insert,
    this.employee_update,
    this.employee_delete,
    required this.manager_insert,
    this.manager_update,
    this.manager_delete,
    required this.assignment_insert,
    this.assignment_update,
    this.assignment_delete,
    required this.skill_insert,
    this.skill_update,
    this.skill_delete,
    required this.employeeSkill_insert,
    this.employeeSkill_update,
    this.employeeSkill_delete,
  });
}

