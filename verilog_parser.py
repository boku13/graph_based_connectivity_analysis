"""
Verilog Parser for RTL Connectivity Analysis
Parses Verilog files and extracts signals and their dependencies
"""

import re
from typing import Dict, List, Set, Tuple
from dataclasses import dataclass, field


@dataclass
class Signal:
    """Represents a signal in the RTL design"""
    name: str
    signal_type: str  # 'input', 'output', 'inout', 'wire', 'reg', 'logic'
    width: str = "1"  # bit width
    is_array: bool = False
    array_dims: List[str] = field(default_factory=list)
    
    def __hash__(self):
        return hash(self.name)
    
    def __eq__(self, other):
        return isinstance(other, Signal) and self.name == other.name


class VerilogParser:
    """Parse Verilog files and extract signals and dependencies"""
    
    def __init__(self):
        self.signals: Dict[str, Signal] = {}
        self.dependencies: List[Tuple[str, str]] = []  # (source, target) edges
        self.module_name = ""
        
    def parse_file(self, filepath: str) -> Tuple[str, Dict[str, Signal], List[Tuple[str, str]]]:
        """Parse a Verilog file and return module name, signals, and dependencies"""
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
        
        # Remove comments
        content = self._remove_comments(content)
        
        # Extract module name
        self.module_name = self._extract_module_name(content)
        
        # Extract signals
        self._extract_signals(content)
        
        # Extract dependencies
        self._extract_dependencies(content)
        
        return self.module_name, self.signals, self.dependencies
    
    def _remove_comments(self, content: str) -> str:
        """Remove single-line and multi-line comments"""
        # Remove multi-line comments
        content = re.sub(r'/\*.*?\*/', '', content, flags=re.DOTALL)
        # Remove single-line comments
        content = re.sub(r'//.*?$', '', content, flags=re.MULTILINE)
        return content
    
    def _extract_module_name(self, content: str) -> str:
        """Extract module name from Verilog content"""
        match = re.search(r'\bmodule\s+(\w+)', content)
        return match.group(1) if match else "unknown_module"
    
    def _extract_signals(self, content: str) -> None:
        """Extract all signals from Verilog content"""
        # Pattern for port declarations (input/output/inout)
        port_pattern = r'\b(input|output|inout)\s+(?:(wire|reg|logic)\s+)?(?:\[([^\]]+)\]\s+)?(\w+(?:\s*\[.*?\])?)'
        
        for match in re.finditer(port_pattern, content):
            direction = match.group(1)
            sig_type = match.group(2) if match.group(2) else 'wire'
            width = match.group(3) if match.group(3) else None
            signal_str = match.group(4).strip()
            
            # Handle array declarations
            signal_name = re.match(r'(\w+)', signal_str).group(1)
            is_array = '[' in signal_str and signal_str.index('[') > len(signal_name)
            
            self.signals[signal_name] = Signal(
                name=signal_name,
                signal_type=direction,
                width=width if width else "1"
            )
        
        # Pattern for internal signals (wire/reg/logic)
        internal_pattern = r'\b(wire|reg|logic)\s+(?:\[([^\]]+)\]\s+)?(\w+(?:\s*\[.*?\])?)'
        
        for match in re.finditer(internal_pattern, content):
            sig_type = match.group(1)
            width = match.group(2) if match.group(2) else None
            signal_str = match.group(3).strip()
            
            # Extract signal name
            signal_name = re.match(r'(\w+)', signal_str).group(1)
            
            if signal_name not in self.signals:
                self.signals[signal_name] = Signal(
                    name=signal_name,
                    signal_type=sig_type,
                    width=width if width else "1"
                )
        
        # Find signals in always blocks (reg outputs)
        reg_pattern = r'\b(output\s+reg)\s+(?:\[([^\]]+)\]\s+)?(\w+)'
        for match in re.finditer(reg_pattern, content):
            width = match.group(2) if match.group(2) else None
            signal_name = match.group(3).strip()
            
            if signal_name not in self.signals:
                self.signals[signal_name] = Signal(
                    name=signal_name,
                    signal_type='output',
                    width=width if width else "1"
                )
        
        # Extract integer declarations (used as signals/counters)
        integer_pattern = r'\binteger\s+(\w+)'
        for match in re.finditer(integer_pattern, content):
            signal_name = match.group(1)
            if signal_name not in self.signals:
                self.signals[signal_name] = Signal(
                    name=signal_name,
                    signal_type='integer',
                    width="31:0"
                )
        
        # Extract signals with custom types (e.g., typedef enum)
        # Pattern: type_name signal1, signal2, ...;
        # This catches: state_t current_state, next_state;
        custom_type_pattern = r'\b([a-zA-Z_]\w*_t)\s+([\w\s,]+);'
        for match in re.finditer(custom_type_pattern, content):
            type_name = match.group(1)
            signal_list = match.group(2)
            
            # Split by comma to get individual signals
            signal_names = [s.strip() for s in signal_list.split(',')]
            
            for signal_name in signal_names:
                # Remove any array dimensions
                signal_name = re.match(r'(\w+)', signal_name).group(1)
                
                if signal_name not in self.signals:
                    self.signals[signal_name] = Signal(
                        name=signal_name,
                        signal_type=type_name,
                        width="custom"
                    )
    
    def _extract_dependencies(self, content: str) -> None:
        """Extract signal dependencies from assignments and always blocks"""
        # Continuous assignments (assign statements)
        assign_pattern = r'\bassign\s+(\w+)(?:\[[^\]]+\])?\s*=\s*([^;]+);'
        
        for match in re.finditer(assign_pattern, content):
            target = match.group(1)  # Signal name without indices
            rhs = match.group(2)
            sources = self._extract_signals_from_expression(rhs)
            
            for source in sources:
                self.dependencies.append((source, target))
        
        # Always blocks with begin/end - use smarter matching to handle nesting
        always_blocks = self._extract_always_blocks(content)
        
        for block_content in always_blocks:
            self._extract_dependencies_from_always_block(block_content)
        
        # Case statements
        case_pattern = r'case\s*\(([^)]+)\)(.*?)endcase'
        for match in re.finditer(case_pattern, content, re.DOTALL):
            case_expr = match.group(1).strip()
            case_body = match.group(2)
            
            # Case expression influences all targets in case body
            case_signals = self._extract_signals_from_expression(case_expr)
            targets = self._extract_targets_from_case(case_body)
            
            for case_sig in case_signals:
                for target in targets:
                    self.dependencies.append((case_sig, target))
            
            # Dependencies within case items
            self._extract_dependencies_from_always_block(case_body)
    
    def _extract_always_blocks(self, content: str) -> List[str]:
        """Extract always blocks handling nested begin/end"""
        blocks = []
        
        # Find all always block starts
        always_pattern = r'always\s*@\s*\([^)]+\)\s*'
        
        for match in re.finditer(always_pattern, content):
            start_pos = match.end()
            
            # Check if it's followed by 'begin'
            if content[start_pos:start_pos+10].strip().startswith('begin'):
                # Find matching end using paren counting
                block = self._extract_balanced_block(content, start_pos)
                if block:
                    blocks.append(block)
            else:
                # Single statement without begin/end
                # Find the semicolon
                end_pos = content.find(';', start_pos)
                if end_pos != -1:
                    blocks.append(content[start_pos:end_pos+1])
        
        return blocks
    
    def _extract_balanced_block(self, content: str, start_pos: int) -> str:
        """Extract content between balanced begin/end keywords"""
        # Skip whitespace and 'begin'
        pos = start_pos
        while pos < len(content) and content[pos].isspace():
            pos += 1
        
        if not content[pos:pos+5] == 'begin':
            return ""
        
        pos += 5  # Skip 'begin'
        begin_count = 1
        block_start = pos
        
        # Find matching end
        i = pos
        while i < len(content) and begin_count > 0:
            # Check for 'begin' keyword
            if content[i:i+5] == 'begin' and (i == 0 or not content[i-1].isalnum()) and \
               (i+5 >= len(content) or not content[i+5].isalnum()):
                begin_count += 1
                i += 5
            # Check for 'end' keyword (but not 'endcase', 'endmodule', etc.)
            elif content[i:i+3] == 'end' and (i == 0 or not content[i-1].isalnum()) and \
                 (i+3 >= len(content) or not content[i+3].isalnum()):
                begin_count -= 1
                if begin_count == 0:
                    return content[block_start:i]
                i += 3
            else:
                i += 1
        
        return content[block_start:i] if begin_count == 0 else ""
    
    def _extract_dependencies_from_always_block(self, block_content: str) -> None:
        """Extract dependencies from always block content"""
        # Non-blocking assignments (including bit-selects and array elements)
        nb_assigns = re.finditer(r'(\w+)(?:\[[^\]]+\])?\s*<=\s*([^;]+);', block_content)
        
        for match in nb_assigns:
            target = match.group(1)  # Just the signal name, no indices
            rhs = match.group(2)
            sources = self._extract_signals_from_expression(rhs)
            
            # Always add dependencies, even for self-referential (e.g., x <= x + 1)
            for source in sources:
                self.dependencies.append((source, target))
        
        # Blocking assignments (including bit-selects and array elements)
        b_assigns = re.finditer(r'(\w+)(?:\[[^\]]+\])?\s*=\s*([^;]+);', block_content)
        
        for match in b_assigns:
            target = match.group(1)  # Just the signal name, no indices
            rhs = match.group(2)
            sources = self._extract_signals_from_expression(rhs)
            
            # Always add dependencies, even for self-referential
            for source in sources:
                self.dependencies.append((source, target))
    
    def _extract_dependencies_from_statement(self, stmt: str) -> None:
        """Extract dependencies from a single statement"""
        # Assignment pattern (handles bit-selects and array elements)
        assign_match = re.match(r'(\w+)(?:\[[^\]]+\])?\s*[<]?=\s*([^;]+)', stmt)
        
        if assign_match:
            target = assign_match.group(1)  # Signal name without indices
            rhs = assign_match.group(2)
            sources = self._extract_signals_from_expression(rhs)
            
            for source in sources:
                self.dependencies.append((source, target))
    
    def _extract_targets_from_case(self, case_body: str) -> Set[str]:
        """Extract all assignment targets from case statement body"""
        targets = set()
        
        # Find all assignments (handles bit-selects and array elements)
        assigns = re.finditer(r'(\w+)(?:\[[^\]]+\])?\s*[<]?=', case_body)
        
        for match in assigns:
            target = match.group(1)  # Signal name without indices
            targets.add(target)
        
        return targets
    
    def _extract_signal_name(self, signal_ref: str) -> str:
        """Extract signal name from reference (may include array indexing)"""
        match = re.match(r'(\w+)', signal_ref.strip())
        return match.group(1) if match else signal_ref.strip()
    
    def _extract_signals_from_expression(self, expr: str) -> Set[str]:
        """Extract all signal references from an expression"""
        signals = set()
        
        # First, extract array accesses like signal[index]
        # This handles: data[i], request[0], fifo_memory[write_ptr], etc.
        array_pattern = r'\b([a-zA-Z_]\w*)\s*\['
        array_matches = re.finditer(array_pattern, expr)
        for match in array_matches:
            signal = match.group(1)
            if not self._is_verilog_keyword(signal) and signal in self.signals:
                signals.add(signal)
        
        # Then find all other identifiers (signals) not part of array accesses
        # Remove array accesses first to avoid double-counting indices
        expr_no_arrays = re.sub(r'\[[^\]]+\]', '', expr)
        identifiers = re.findall(r'\b([a-zA-Z_]\w*)\b', expr_no_arrays)
        
        for ident in identifiers:
            # Filter out Verilog keywords and numeric literals
            if not self._is_verilog_keyword(ident) and ident in self.signals:
                signals.add(ident)
        
        return signals
    
    def _is_verilog_keyword(self, word: str) -> bool:
        """Check if a word is a Verilog keyword"""
        keywords = {
            'if', 'else', 'case', 'endcase', 'default', 'for', 'while',
            'begin', 'end', 'posedge', 'negedge', 'or', 'and', 'not',
            'module', 'endmodule', 'always', 'assign', 'wire', 'reg',
            'input', 'output', 'inout', 'parameter', 'localparam',
            'genvar', 'generate', 'endgenerate', 'initial', 'int'
        }
        return word.lower() in keywords


def parse_verilog_file(filepath: str) -> Tuple[str, Dict[str, Signal], List[Tuple[str, str]]]:
    """Convenience function to parse a Verilog file"""
    parser = VerilogParser()
    return parser.parse_file(filepath)
