part of 'generated.dart';

class ReadDataVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  ReadDataVariablesBuilder(this._dataConnect, );
  Deserializer<ReadDataData> dataDeserializer = (dynamic json)  => ReadDataData.fromJson(jsonDecode(json));
  
  Future<QueryResult<ReadDataData, void>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<ReadDataData, void> ref() {
    
    return _dataConnect.query("ReadData", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class ReadDataDepartments {
  final String name;
  final String? location;
  ReadDataDepartments.fromJson(dynamic json):
  
  name = nativeFromJson<String>(json['name']),
  location = json['location'] == null ? null : nativeFromJson<String>(json['location']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ReadDataDepartments otherTyped = other as ReadDataDepartments;
    return name == otherTyped.name && 
    location == otherTyped.location;
    
  }
  @override
  int get hashCode => Object.hashAll([name.hashCode, location.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['name'] = nativeToJson<String>(name);
    if (location != null) {
      json['location'] = nativeToJson<String?>(location);
    }
    return json;
  }

  ReadDataDepartments({
    required this.name,
    this.location,
  });
}

@immutable
class ReadDataEmployees {
  final String firstName;
  final String lastName;
  final String email;
  ReadDataEmployees.fromJson(dynamic json):
  
  firstName = nativeFromJson<String>(json['firstName']),
  lastName = nativeFromJson<String>(json['lastName']),
  email = nativeFromJson<String>(json['email']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ReadDataEmployees otherTyped = other as ReadDataEmployees;
    return firstName == otherTyped.firstName && 
    lastName == otherTyped.lastName && 
    email == otherTyped.email;
    
  }
  @override
  int get hashCode => Object.hashAll([firstName.hashCode, lastName.hashCode, email.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['firstName'] = nativeToJson<String>(firstName);
    json['lastName'] = nativeToJson<String>(lastName);
    json['email'] = nativeToJson<String>(email);
    return json;
  }

  ReadDataEmployees({
    required this.firstName,
    required this.lastName,
    required this.email,
  });
}

@immutable
class ReadDataManagers {
  final String? title;
  final ReadDataManagersEmployee employee;
  ReadDataManagers.fromJson(dynamic json):
  
  title = json['title'] == null ? null : nativeFromJson<String>(json['title']),
  employee = ReadDataManagersEmployee.fromJson(json['employee']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ReadDataManagers otherTyped = other as ReadDataManagers;
    return title == otherTyped.title && 
    employee == otherTyped.employee;
    
  }
  @override
  int get hashCode => Object.hashAll([title.hashCode, employee.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (title != null) {
      json['title'] = nativeToJson<String?>(title);
    }
    json['employee'] = employee.toJson();
    return json;
  }

  ReadDataManagers({
    this.title,
    required this.employee,
  });
}

@immutable
class ReadDataManagersEmployee {
  final String firstName;
  final String lastName;
  ReadDataManagersEmployee.fromJson(dynamic json):
  
  firstName = nativeFromJson<String>(json['firstName']),
  lastName = nativeFromJson<String>(json['lastName']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ReadDataManagersEmployee otherTyped = other as ReadDataManagersEmployee;
    return firstName == otherTyped.firstName && 
    lastName == otherTyped.lastName;
    
  }
  @override
  int get hashCode => Object.hashAll([firstName.hashCode, lastName.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['firstName'] = nativeToJson<String>(firstName);
    json['lastName'] = nativeToJson<String>(lastName);
    return json;
  }

  ReadDataManagersEmployee({
    required this.firstName,
    required this.lastName,
  });
}

@immutable
class ReadDataAssignments {
  final DateTime startDate;
  final String status;
  final ReadDataAssignmentsEmployee employee;
  final ReadDataAssignmentsDepartment department;
  ReadDataAssignments.fromJson(dynamic json):
  
  startDate = nativeFromJson<DateTime>(json['startDate']),
  status = nativeFromJson<String>(json['status']),
  employee = ReadDataAssignmentsEmployee.fromJson(json['employee']),
  department = ReadDataAssignmentsDepartment.fromJson(json['department']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ReadDataAssignments otherTyped = other as ReadDataAssignments;
    return startDate == otherTyped.startDate && 
    status == otherTyped.status && 
    employee == otherTyped.employee && 
    department == otherTyped.department;
    
  }
  @override
  int get hashCode => Object.hashAll([startDate.hashCode, status.hashCode, employee.hashCode, department.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['startDate'] = nativeToJson<DateTime>(startDate);
    json['status'] = nativeToJson<String>(status);
    json['employee'] = employee.toJson();
    json['department'] = department.toJson();
    return json;
  }

  ReadDataAssignments({
    required this.startDate,
    required this.status,
    required this.employee,
    required this.department,
  });
}

@immutable
class ReadDataAssignmentsEmployee {
  final String firstName;
  ReadDataAssignmentsEmployee.fromJson(dynamic json):
  
  firstName = nativeFromJson<String>(json['firstName']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ReadDataAssignmentsEmployee otherTyped = other as ReadDataAssignmentsEmployee;
    return firstName == otherTyped.firstName;
    
  }
  @override
  int get hashCode => firstName.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['firstName'] = nativeToJson<String>(firstName);
    return json;
  }

  ReadDataAssignmentsEmployee({
    required this.firstName,
  });
}

@immutable
class ReadDataAssignmentsDepartment {
  final String name;
  ReadDataAssignmentsDepartment.fromJson(dynamic json):
  
  name = nativeFromJson<String>(json['name']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ReadDataAssignmentsDepartment otherTyped = other as ReadDataAssignmentsDepartment;
    return name == otherTyped.name;
    
  }
  @override
  int get hashCode => name.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['name'] = nativeToJson<String>(name);
    return json;
  }

  ReadDataAssignmentsDepartment({
    required this.name,
  });
}

@immutable
class ReadDataSkills {
  final String name;
  final String? category;
  ReadDataSkills.fromJson(dynamic json):
  
  name = nativeFromJson<String>(json['name']),
  category = json['category'] == null ? null : nativeFromJson<String>(json['category']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ReadDataSkills otherTyped = other as ReadDataSkills;
    return name == otherTyped.name && 
    category == otherTyped.category;
    
  }
  @override
  int get hashCode => Object.hashAll([name.hashCode, category.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['name'] = nativeToJson<String>(name);
    if (category != null) {
      json['category'] = nativeToJson<String?>(category);
    }
    return json;
  }

  ReadDataSkills({
    required this.name,
    this.category,
  });
}

@immutable
class ReadDataEmployeeSkills {
  final ReadDataEmployeeSkillsEmployee employee;
  final ReadDataEmployeeSkillsSkill skill;
  ReadDataEmployeeSkills.fromJson(dynamic json):
  
  employee = ReadDataEmployeeSkillsEmployee.fromJson(json['employee']),
  skill = ReadDataEmployeeSkillsSkill.fromJson(json['skill']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ReadDataEmployeeSkills otherTyped = other as ReadDataEmployeeSkills;
    return employee == otherTyped.employee && 
    skill == otherTyped.skill;
    
  }
  @override
  int get hashCode => Object.hashAll([employee.hashCode, skill.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['employee'] = employee.toJson();
    json['skill'] = skill.toJson();
    return json;
  }

  ReadDataEmployeeSkills({
    required this.employee,
    required this.skill,
  });
}

@immutable
class ReadDataEmployeeSkillsEmployee {
  final String firstName;
  ReadDataEmployeeSkillsEmployee.fromJson(dynamic json):
  
  firstName = nativeFromJson<String>(json['firstName']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ReadDataEmployeeSkillsEmployee otherTyped = other as ReadDataEmployeeSkillsEmployee;
    return firstName == otherTyped.firstName;
    
  }
  @override
  int get hashCode => firstName.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['firstName'] = nativeToJson<String>(firstName);
    return json;
  }

  ReadDataEmployeeSkillsEmployee({
    required this.firstName,
  });
}

@immutable
class ReadDataEmployeeSkillsSkill {
  final String name;
  ReadDataEmployeeSkillsSkill.fromJson(dynamic json):
  
  name = nativeFromJson<String>(json['name']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ReadDataEmployeeSkillsSkill otherTyped = other as ReadDataEmployeeSkillsSkill;
    return name == otherTyped.name;
    
  }
  @override
  int get hashCode => name.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['name'] = nativeToJson<String>(name);
    return json;
  }

  ReadDataEmployeeSkillsSkill({
    required this.name,
  });
}

@immutable
class ReadDataDepartment {
  final String name;
  ReadDataDepartment.fromJson(dynamic json):
  
  name = nativeFromJson<String>(json['name']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ReadDataDepartment otherTyped = other as ReadDataDepartment;
    return name == otherTyped.name;
    
  }
  @override
  int get hashCode => name.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['name'] = nativeToJson<String>(name);
    return json;
  }

  ReadDataDepartment({
    required this.name,
  });
}

@immutable
class ReadDataEmployee {
  final String firstName;
  final String lastName;
  ReadDataEmployee.fromJson(dynamic json):
  
  firstName = nativeFromJson<String>(json['firstName']),
  lastName = nativeFromJson<String>(json['lastName']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ReadDataEmployee otherTyped = other as ReadDataEmployee;
    return firstName == otherTyped.firstName && 
    lastName == otherTyped.lastName;
    
  }
  @override
  int get hashCode => Object.hashAll([firstName.hashCode, lastName.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['firstName'] = nativeToJson<String>(firstName);
    json['lastName'] = nativeToJson<String>(lastName);
    return json;
  }

  ReadDataEmployee({
    required this.firstName,
    required this.lastName,
  });
}

@immutable
class ReadDataData {
  final List<ReadDataDepartments> departments;
  final List<ReadDataEmployees> employees;
  final List<ReadDataManagers> managers;
  final List<ReadDataAssignments> assignments;
  final List<ReadDataSkills> skills;
  final List<ReadDataEmployeeSkills> employeeSkills;
  final ReadDataDepartment? department;
  final ReadDataEmployee? employee;
  ReadDataData.fromJson(dynamic json):
  
  departments = (json['departments'] as List<dynamic>)
        .map((e) => ReadDataDepartments.fromJson(e))
        .toList(),
  employees = (json['employees'] as List<dynamic>)
        .map((e) => ReadDataEmployees.fromJson(e))
        .toList(),
  managers = (json['managers'] as List<dynamic>)
        .map((e) => ReadDataManagers.fromJson(e))
        .toList(),
  assignments = (json['assignments'] as List<dynamic>)
        .map((e) => ReadDataAssignments.fromJson(e))
        .toList(),
  skills = (json['skills'] as List<dynamic>)
        .map((e) => ReadDataSkills.fromJson(e))
        .toList(),
  employeeSkills = (json['employeeSkills'] as List<dynamic>)
        .map((e) => ReadDataEmployeeSkills.fromJson(e))
        .toList(),
  department = json['department'] == null ? null : ReadDataDepartment.fromJson(json['department']),
  employee = json['employee'] == null ? null : ReadDataEmployee.fromJson(json['employee']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ReadDataData otherTyped = other as ReadDataData;
    return departments == otherTyped.departments && 
    employees == otherTyped.employees && 
    managers == otherTyped.managers && 
    assignments == otherTyped.assignments && 
    skills == otherTyped.skills && 
    employeeSkills == otherTyped.employeeSkills && 
    department == otherTyped.department && 
    employee == otherTyped.employee;
    
  }
  @override
  int get hashCode => Object.hashAll([departments.hashCode, employees.hashCode, managers.hashCode, assignments.hashCode, skills.hashCode, employeeSkills.hashCode, department.hashCode, employee.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['departments'] = departments.map((e) => e.toJson()).toList();
    json['employees'] = employees.map((e) => e.toJson()).toList();
    json['managers'] = managers.map((e) => e.toJson()).toList();
    json['assignments'] = assignments.map((e) => e.toJson()).toList();
    json['skills'] = skills.map((e) => e.toJson()).toList();
    json['employeeSkills'] = employeeSkills.map((e) => e.toJson()).toList();
    if (department != null) {
      json['department'] = department!.toJson();
    }
    if (employee != null) {
      json['employee'] = employee!.toJson();
    }
    return json;
  }

  ReadDataData({
    required this.departments,
    required this.employees,
    required this.managers,
    required this.assignments,
    required this.skills,
    required this.employeeSkills,
    this.department,
    this.employee,
  });
}

