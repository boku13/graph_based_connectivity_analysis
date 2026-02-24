"""
Graph Builder for RTL Connectivity Analysis
Constructs a directed dependency graph from parsed Verilog signals and dependencies
"""

from typing import Dict, List, Set, Tuple
from collections import defaultdict
import networkx as nx
from verilog_parser import Signal


class DependencyGraph:
    """Directed dependency graph representing RTL-level dataflow"""
    
    def __init__(self, module_name: str):
        self.module_name = module_name
        self.graph = nx.DiGraph()
        self.signals: Dict[str, Signal] = {}
        
    def add_signal(self, signal: Signal) -> None:
        """Add a signal as a node in the graph"""
        self.signals[signal.name] = signal
        self.graph.add_node(signal.name, 
                          signal_type=signal.signal_type,
                          width=signal.width)
    
    def add_dependency(self, source: str, target: str) -> None:
        """Add a dependency edge from source to target"""
        # Only add if both signals exist
        if source in self.signals and target in self.signals:
            self.graph.add_edge(source, target)
    
    def get_fan_in(self, signal: str) -> Set[str]:
        """Get all unique signals that directly drive/affect this signal"""
        if signal in self.graph:
            return set(self.graph.predecessors(signal))
        return set()
    
    def get_fan_out(self, signal: str) -> Set[str]:
        """Get all unique signals directly driven/affected by this signal"""
        if signal in self.graph:
            return set(self.graph.successors(signal))
        return set()
    
    def get_fan_in_count(self, signal: str) -> int:
        """Get the fan-in count (number of unique predecessors)"""
        return len(self.get_fan_in(signal))
    
    def get_fan_out_count(self, signal: str) -> int:
        """Get the fan-out count (number of unique successors)"""
        return len(self.get_fan_out(signal))
    
    def get_all_signals(self) -> List[str]:
        """Get list of all signals in the graph"""
        return list(self.graph.nodes())
    
    def get_signal_info(self, signal: str) -> Signal:
        """Get Signal object for a given signal name"""
        return self.signals.get(signal, None)
    
    def compute_connectivity_metrics(self) -> Dict[str, Dict[str, any]]:
        """Compute connectivity metrics for all signals"""
        metrics = {}
        
        for signal in self.get_all_signals():
            fan_in = self.get_fan_in(signal)
            fan_out = self.get_fan_out(signal)
            
            metrics[signal] = {
                'fan_in_count': len(fan_in),
                'fan_out_count': len(fan_out),
                'fan_in_signals': sorted(list(fan_in)),
                'fan_out_signals': sorted(list(fan_out)),
                'signal_type': self.signals[signal].signal_type if signal in self.signals else 'unknown',
                'width': self.signals[signal].width if signal in self.signals else '1'
            }
        
        return metrics
    
    def get_top_k_fan_in(self, k: int = 10) -> List[Tuple[str, int, List[str]]]:
        """
        Get top K signals with highest fan-in
        Returns: List of (signal_name, fan_in_count, list_of_drivers)
        """
        results = []
        
        for signal in self.get_all_signals():
            fan_in_signals = self.get_fan_in(signal)
            fan_in_count = len(fan_in_signals)
            
            if fan_in_count > 0:
                results.append((signal, fan_in_count, sorted(list(fan_in_signals))))
        
        # Sort by fan-in count (descending)
        results.sort(key=lambda x: x[1], reverse=True)
        
        return results[:k]
    
    def get_top_k_fan_out(self, k: int = 10) -> List[Tuple[str, int, List[str]]]:
        """
        Get top K signals with highest fan-out
        Returns: List of (signal_name, fan_out_count, list_of_loads)
        """
        results = []
        
        for signal in self.get_all_signals():
            fan_out_signals = self.get_fan_out(signal)
            fan_out_count = len(fan_out_signals)
            
            if fan_out_count > 0:
                results.append((signal, fan_out_count, sorted(list(fan_out_signals))))
        
        # Sort by fan-out count (descending)
        results.sort(key=lambda x: x[1], reverse=True)
        
        return results[:k]
    
    def get_statistics(self) -> Dict[str, any]:
        """Get overall graph statistics"""
        num_nodes = self.graph.number_of_nodes()
        num_edges = self.graph.number_of_edges()
        
        # Count signal types
        signal_types = defaultdict(int)
        for signal in self.signals.values():
            signal_types[signal.signal_type] += 1
        
        # Calculate average fan-in and fan-out
        total_fan_in = sum(self.get_fan_in_count(s) for s in self.get_all_signals())
        total_fan_out = sum(self.get_fan_out_count(s) for s in self.get_all_signals())
        
        avg_fan_in = total_fan_in / num_nodes if num_nodes > 0 else 0
        avg_fan_out = total_fan_out / num_nodes if num_nodes > 0 else 0
        
        return {
            'module_name': self.module_name,
            'total_signals': num_nodes,
            'total_dependencies': num_edges,
            'signal_types': dict(signal_types),
            'average_fan_in': round(avg_fan_in, 2),
            'average_fan_out': round(avg_fan_out, 2)
        }


def build_dependency_graph(module_name: str, signals: Dict[str, Signal], 
                          dependencies: List[Tuple[str, str]]) -> DependencyGraph:
    """Build a dependency graph from parsed signals and dependencies"""
    graph = DependencyGraph(module_name)
    
    # Add all signals as nodes
    for signal in signals.values():
        graph.add_signal(signal)
    
    # Add all dependencies as edges (remove duplicates)
    unique_deps = set(dependencies)
    for source, target in unique_deps:
        graph.add_dependency(source, target)
    
    return graph
