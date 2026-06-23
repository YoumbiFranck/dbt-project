#!/usr/bin/env python3
"""
Automated Data Transformation Model Generator
Course: Automate, Optimize, and Benchmark Data Pipelines
Module 2: Pipeline automation and optimization - Core Application & Assessment

This script generates SQL transformation models from YAML configuration files,
enabling scalable and consistent data pipeline development.

IMPORTANT: Before running this script, you MUST create 'sample_transform_config.yml' 
in the same directory. See lab documentation for the complete file structure.
"""

import os
import yaml
from datetime import datetime
from typing import Dict, List, Any, Optional

# PROVIDED CODE - DO NOT MODIFY
class ModelGeneratorError(Exception):
    """Custom exception for model generation errors"""
    pass

def setup_output_directory(base_path: str = "generated_models") -> str:
    """
    Create organized directory structure for generated models
    
    Args:
        base_path: Base directory for model output
    
    Returns:
        str: Path to created directory
    """
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    output_dir = os.path.join(base_path, f"models_{timestamp}")
    
    try:
        os.makedirs(output_dir, exist_ok=True)
        print(f"✅ Created output directory: {output_dir}")
        return output_dir
    except OSError as e:
        raise ModelGeneratorError(f"Failed to create output directory: {e}")

def check_config_file_exists(config_path: str) -> None:
    """
    Check if the required configuration file exists and provide helpful guidance
    
    Args:
        config_path: Path to configuration file
    
    Raises:
        ModelGeneratorError: If configuration file doesn't exist with setup instructions
    """
    if not os.path.exists(config_path):
        error_msg = f"""
❌ Configuration file not found: {config_path}

🚨 SETUP REQUIRED: You must create the YAML configuration file before running this script.

📋 To fix this issue:
1. Create a file named 'sample_transform_config.yml' in this directory
2. Copy the complete YAML structure from the lab documentation
3. Ensure the file is in the same folder as this Python script

💡 The configuration file defines your data transformation specifications.
Without it, the automation script cannot generate SQL models.
        """
        raise ModelGeneratorError(error_msg.strip())

### PRACTICE CHALLENGE 1 ###
# TASK: Complete the configuration parser that loads YAML files, validates required fields
# (source_table, target_table, transformations), and returns structured configuration with error handling

def load_and_validate_config(config_path: str) -> Dict[str, Any]:
    """
    Load and validate YAML configuration file

    Args:
        config_path: Path to YAML configuration file

    Returns:
        Dict containing validated configuration

    Raises:
        ModelGeneratorError: If configuration is invalid or missing required fields
    """
    check_config_file_exists(config_path)

    try:
        with open(config_path, 'r') as f:
            config = yaml.safe_load(f)
    except yaml.YAMLError as e:
        raise ModelGeneratorError(f"Invalid YAML syntax in configuration file: {e}")

    if not isinstance(config, dict):
        raise ModelGeneratorError("Configuration file must contain a YAML mapping (key-value pairs)")

    required_fields = ['source_table', 'target_table', 'transformations']
    missing_fields = [field for field in required_fields if field not in config]
    if missing_fields:
        raise ModelGeneratorError(
            f"Missing required configuration fields: {', '.join(missing_fields)}\n"
            f"All required fields: {', '.join(required_fields)}"
        )

    if not isinstance(config['transformations'], dict):
        raise ModelGeneratorError("'transformations' must be a YAML mapping of column names to SQL expressions")

    return config

# PROVIDED CODE - DO NOT MODIFY
def get_sql_template() -> str:
    """
    Return base SQL template for transformation models
    
    Returns:
        str: SQL template with placeholders
    """
    return '''-- Generated SQL Transformation Model
-- Source: {source_table}
-- Target: {target_table}
-- Generated: {timestamp}
-- Configuration: {config_file}

WITH source_data AS (
    SELECT {source_columns}
    FROM {source_table}
    {where_clause}
),
transformed_data AS (
    SELECT
        {transformation_logic}
    FROM source_data
    {join_clause}
    {group_by_clause}
)
SELECT * FROM transformed_data
{order_by_clause};'''

### PRACTICE CHALLENGE 2 ###
# TASK: Implement SQL model generation that takes configuration parameters and produces
# complete SQL transformation model with SELECT, JOIN, and WHERE logic based on config specs

def generate_sql_model(config: Dict[str, Any], config_file: str = "config.yml") -> str:
    """
    Generate SQL transformation model from configuration

    Args:
        config: Validated configuration dictionary
        config_file: Name of source configuration file

    Returns:
        str: Complete SQL transformation model
    """
    template = get_sql_template()

    source_table = config['source_table']
    target_table = config['target_table']
    transformations = config['transformations']

    # source_columns: explicit list or default to wildcard
    cols = config.get('source_columns')
    source_columns = ', '.join(cols) if cols else '*'

    # WHERE clause: join conditions with AND
    where_conditions = config.get('where_conditions', [])
    if where_conditions:
        where_clause = 'WHERE ' + '\n    AND '.join(where_conditions)
    else:
        where_clause = ''

    # transformation_logic: "expression AS alias" for each mapping entry
    transformation_lines = [
        f'{expr} AS {alias}'
        for alias, expr in transformations.items()
    ]
    transformation_logic = ',\n        '.join(transformation_lines)

    # JOIN clause: one line per join
    joins = config.get('joins', [])
    if joins:
        join_parts = [
            f"{j['type']} JOIN {j['table']} ON {j['condition']}"
            for j in joins
        ]
        join_clause = '\n    '.join(join_parts)
    else:
        join_clause = ''

    # GROUP BY clause
    group_by = config.get('group_by', [])
    group_by_clause = f"GROUP BY {', '.join(group_by)}" if group_by else ''

    # ORDER BY clause
    order_by = config.get('order_by', [])
    order_by_clause = f"ORDER BY {', '.join(order_by)}" if order_by else ''

    return template.format(
        source_table=source_table,
        target_table=target_table,
        timestamp=datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        config_file=config_file,
        source_columns=source_columns,
        where_clause=where_clause,
        transformation_logic=transformation_logic,
        join_clause=join_clause,
        group_by_clause=group_by_clause,
        order_by_clause=order_by_clause,
    )

def validate_sql_syntax(sql_content: str) -> bool:
    """
    Basic SQL syntax validation
    
    Args:
        sql_content: Generated SQL to validate
    
    Returns:
        bool: True if basic validation passes
    """
    # PROVIDED CODE - DO NOT MODIFY
    required_keywords = ['SELECT', 'FROM']
    sql_upper = sql_content.upper()
    
    for keyword in required_keywords:
        if keyword not in sql_upper:
            return False
    
    # Check for basic SQL structure
    if sql_upper.count('SELECT') == 0 or sql_upper.count('FROM') == 0:
        return False
    
    return True

### PRACTICE CHALLENGE 3 ###
# TASK: Create file output function that saves generated SQL models with organized directory structure,
# validates SQL syntax, and generates summary report of created files
# YOUR CODE HERE

def save_model_and_generate_report(sql_content: str, config: Dict[str, Any],
                                 output_dir: str, config_file: str) -> Dict[str, Any]:
    """
    Save generated SQL model and create summary report
    
    Args:
        sql_content: Generated SQL model content
        config: Configuration used for generation
        output_dir: Directory to save files
        config_file: Source configuration file name
    
    Returns:
        Dict containing file information and validation results
    """
    # Create filename based on target_table and timestamp
    # Validate SQL syntax before saving
    # Save SQL file to output directory
    # Return summary information for reporting
    
    pass

def process_single_config(config_path: str, output_dir: str) -> Dict[str, Any]:
    """
    Process a single configuration file and generate SQL model
    
    Args:
        config_path: Path to configuration file
        output_dir: Output directory for generated models
    
    Returns:
        Dict containing processing results
    """
    # PROVIDED CODE - DO NOT MODIFY
    try:
        print(f"\n🔄 Processing configuration: {config_path}")
        
        # Load and validate configuration
        config = load_and_validate_config(config_path)
        print(f"✅ Configuration loaded and validated")
        
        # Generate SQL model
        sql_content = generate_sql_model(config, os.path.basename(config_path))
        print(f"✅ SQL model generated")
        
        # Save model and generate report
        result = save_model_and_generate_report(sql_content, config, output_dir, config_path)
        print(f"✅ Model saved: {result.get('filename', 'unknown')}")
        
        return result
        
    except Exception as e:
        error_msg = f"❌ Error processing {config_path}: {str(e)}"
        print(error_msg)
        return {
            'config_file': config_path,
            'status': 'error',
            'error': str(e),
            'filename': None
        }

def main():
    """
    Main function to demonstrate the model generator
    """
    # PROVIDED CODE - DO NOT MODIFY
    print("🚀 Data Transformation Model Generator")
    print("=" * 50)
    
    # Setup output directory
    try:
        output_dir = setup_output_directory()
    except ModelGeneratorError as e:
        print(f"❌ Setup failed: {e}")
        return
    
    # Sample configuration for demonstration
    sample_config_path = "sample_transform_config.yml"
    
    # Check for configuration file before processing
    try:
        check_config_file_exists(sample_config_path)
        print(f"✅ Configuration file found: {sample_config_path}")
    except ModelGeneratorError as e:
        print(str(e))
        return
    
    # Process configuration
    result = process_single_config(sample_config_path, output_dir)
    
    # Print summary
    print("\n📊 Generation Summary")
    print("=" * 30)
    if result['status'] == 'success':
        print(f"✅ Successfully generated: {result['filename']}")
        print(f"📋 Source table: {result.get('source_table', 'N/A')}")
        print(f"🎯 Target table: {result.get('target_table', 'N/A')}")
        print(f"✓ SQL validation: {'Passed' if result.get('sql_valid', False) else 'Failed'}")
    else:
        print(f"❌ Generation failed: {result.get('error', 'Unknown error')}")

if __name__ == "__main__":
    main()
